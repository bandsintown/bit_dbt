#!/usr/bin/env python3
"""
dbt Layering Standards Validator

This script validates that all dbt models in the project follow the
hierarchy standards defined in DBT_LAYERING_STANDARDS.md.

Run before pushing:
    python scripts/validate_layering.py

Exit code 0 = all models pass
Exit code 1 = violations found
"""

import os
import re
import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple

# --- Configuration ---
MODELS_DIR = Path(__file__).parent.parent / "models"

# Patterns
REF_PATTERN = re.compile(r"{{\s*ref\(\s*['\"]([^'\"]+)['\"]\s*\)\s*}}")
SOURCE_PATTERN = re.compile(r"{{\s*source\(\s*['\"]([^'\"]+)['\"]\s*,\s*['\"]([^'\"]+)['\"]\s*\)\s*}}")
WHERE_PATTERN = re.compile(r"\bwhere\b", re.IGNORECASE)
JOIN_PATTERN = re.compile(r"\bjoin\b", re.IGNORECASE)
GROUP_BY_PATTERN = re.compile(r"\bgroup\s+by\b", re.IGNORECASE)
UNION_PATTERN = re.compile(r"\bunion\b", re.IGNORECASE)
WINDOW_PATTERN = re.compile(r"\bover\s*\(", re.IGNORECASE)


def get_model_layer(model_name: str, file_path: Path) -> str:
    """Determine the layer of a model based on its name and path."""
    rel_path = str(file_path.relative_to(MODELS_DIR))

    if rel_path.startswith("staging/"):
        return "staging"
    elif rel_path.startswith("intermediate/"):
        return "intermediate"
    elif model_name.startswith("dim_"):
        return "dimension"
    elif model_name.startswith("fct_"):
        return "fact"
    elif model_name.startswith("mart_"):
        return "mart"
    elif rel_path.startswith("marts/"):
        # Models in marts/ without a prefix — infer from name
        if "dim" in model_name:
            return "dimension"
        elif "fct" in model_name or "fact" in model_name:
            return "fact"
        elif "mart" in model_name:
            return "mart"
        return "mart"  # default for models in marts/
    else:
        return "unknown"


def get_layer_from_ref_name(ref_name: str) -> str:
    """Determine the layer of a referenced model by its name prefix."""
    if ref_name.startswith("stg_"):
        return "staging"
    elif ref_name.startswith("int_"):
        return "intermediate"
    elif ref_name.startswith("dim_"):
        return "dimension"
    elif ref_name.startswith("fct_"):
        return "fact"
    elif ref_name.startswith("mart_"):
        return "mart"
    return "unknown"


def strip_sql_comments(content: str) -> str:
    """Remove SQL comments (-- and /* */) from content."""
    # Remove single-line comments
    content = re.sub(r"--.*$", "", content, flags=re.MULTILINE)
    # Remove multi-line comments
    content = re.sub(r"/\*.*?\*/", "", content, flags=re.DOTALL)
    return content


def strip_jinja_config(content: str) -> str:
    """Remove jinja config blocks to avoid false positives."""
    # Remove {{ config(...) }}
    content = re.sub(r"\{\{\s*config\(.*?\)\s*\}\}", "", content, flags=re.DOTALL)
    return content


def validate_staging(model_name: str, file_path: Path, content: str) -> List[str]:
    """Validate staging model rules."""
    violations = []
    clean_content = strip_jinja_config(strip_sql_comments(content))

    # Must use source(), not ref()
    refs = REF_PATTERN.findall(content)
    if refs:
        violations.append(
            f"  ❌ Uses ref() [{', '.join(refs)}] — staging must only use source()"
        )

    sources = SOURCE_PATTERN.findall(content)
    if not sources:
        violations.append("  ❌ No source() found — staging must read from a source")

    # Must not have WHERE
    if WHERE_PATTERN.search(clean_content):
        violations.append("  ❌ Contains WHERE clause — filtering belongs in dims")

    # Must not have JOIN
    if JOIN_PATTERN.search(clean_content):
        violations.append("  ❌ Contains JOIN — joins belong in intermediate or higher")

    # Must not have GROUP BY
    if GROUP_BY_PATTERN.search(clean_content):
        violations.append("  ❌ Contains GROUP BY — aggregation belongs in facts/marts")

    # Must not have UNION
    if UNION_PATTERN.search(clean_content):
        violations.append("  ❌ Contains UNION — unions belong in intermediate")

    # Must not have window functions
    if WINDOW_PATTERN.search(clean_content):
        violations.append("  ❌ Contains window function (OVER) — belongs in dims or higher")

    return violations


def validate_dimension(model_name: str, file_path: Path, content: str) -> List[str]:
    """Validate dimension model rules."""
    violations = []

    refs = REF_PATTERN.findall(content)
    sources = SOURCE_PATTERN.findall(content)

    # Must not use source() directly
    if sources:
        violations.append(
            f"  ❌ Uses source() directly — dims must read from staging (ref('stg_...'))"
        )

    # Must only reference staging models
    for ref_name in refs:
        ref_layer = get_layer_from_ref_name(ref_name)
        if ref_layer != "staging" and ref_layer != "unknown":
            violations.append(
                f"  ❌ References {ref_name} ({ref_layer}) — dims must only read from staging"
            )

    # Must not reference other dims
    for ref_name in refs:
        if ref_name.startswith("dim_"):
            violations.append(
                f"  ❌ References {ref_name} — dim-to-dim references are not allowed"
            )

    return violations


def validate_intermediate(model_name: str, file_path: Path, content: str) -> List[str]:
    """Validate intermediate model rules."""
    violations = []

    refs = REF_PATTERN.findall(content)
    sources = SOURCE_PATTERN.findall(content)

    # Must not use source() directly
    if sources:
        violations.append(
            f"  ❌ Uses source() — intermediate must use ref() to dims or staging"
        )

    # Should reference dims (or staging if no dim exists)
    for ref_name in refs:
        ref_layer = get_layer_from_ref_name(ref_name)
        if ref_layer in ("fact", "mart"):
            violations.append(
                f"  ❌ References {ref_name} ({ref_layer}) — intermediate cannot reference facts or marts"
            )

    return violations


def validate_fact(model_name: str, file_path: Path, content: str) -> List[str]:
    """Validate fact model rules."""
    violations = []

    refs = REF_PATTERN.findall(content)
    sources = SOURCE_PATTERN.findall(content)

    # Must not use source()
    if sources:
        violations.append(
            f"  ❌ Uses source() — facts must read from dims/intermediate/other facts"
        )

    # Must not reference staging directly
    for ref_name in refs:
        ref_layer = get_layer_from_ref_name(ref_name)
        if ref_layer == "staging":
            violations.append(
                f"  ❌ References {ref_name} (staging) — facts cannot read from staging directly"
            )
        elif ref_layer == "mart":
            violations.append(
                f"  ❌ References {ref_name} (mart) — facts cannot reference marts"
            )

    return violations


def validate_mart(model_name: str, file_path: Path, content: str) -> List[str]:
    """Validate mart model rules."""
    violations = []

    refs = REF_PATTERN.findall(content)
    sources = SOURCE_PATTERN.findall(content)

    # Must not use source()
    if sources:
        violations.append(
            f"  ❌ Uses source() — marts must read from facts/dims only"
        )

    # Must only reference facts or dims
    for ref_name in refs:
        ref_layer = get_layer_from_ref_name(ref_name)
        if ref_layer == "staging":
            violations.append(
                f"  ❌ References {ref_name} (staging) — marts cannot read from staging"
            )
        elif ref_layer == "intermediate":
            violations.append(
                f"  ❌ References {ref_name} (intermediate) — marts cannot read from intermediate"
            )

    return violations


def validate_naming(model_name: str, file_path: Path, layer: str) -> List[str]:
    """Validate model naming conventions."""
    violations = []

    expected_prefixes = {
        "staging": "stg_",
        "intermediate": "int_",
        "dimension": "dim_",
        "fact": "fct_",
        "mart": "mart_",
    }

    if layer in expected_prefixes:
        prefix = expected_prefixes[layer]
        if not model_name.startswith(prefix) and layer != "unknown":
            # For dims/facts/marts inferred from path, naming is more flexible
            if layer in ("dimension", "fact", "mart"):
                pass  # Already inferred from name, so prefix must be correct
            else:
                violations.append(
                    f"  ⚠️  Name '{model_name}' should start with '{prefix}' for {layer} layer"
                )

    return violations


def scan_models() -> Tuple[int, int, List[str]]:
    """Scan all models and validate layering rules."""
    total_models = 0
    total_violations = 0
    all_output: List[str] = []

    for sql_file in sorted(MODELS_DIR.rglob("*.sql")):
        model_name = sql_file.stem
        content = sql_file.read_text()

        layer = get_model_layer(model_name, sql_file)

        if layer == "unknown":
            continue

        total_models += 1
        violations: List[str] = []

        # Validate based on layer
        if layer == "staging":
            violations.extend(validate_staging(model_name, sql_file, content))
        elif layer == "dimension":
            violations.extend(validate_dimension(model_name, sql_file, content))
        elif layer == "intermediate":
            violations.extend(validate_intermediate(model_name, sql_file, content))
        elif layer == "fact":
            violations.extend(validate_fact(model_name, sql_file, content))
        elif layer == "mart":
            violations.extend(validate_mart(model_name, sql_file, content))

        # Validate naming
        violations.extend(validate_naming(model_name, sql_file, layer))

        if violations:
            total_violations += len(violations)
            rel_path = sql_file.relative_to(MODELS_DIR)
            all_output.append(f"\n🚨 {rel_path} [{layer}]")
            all_output.extend(violations)

    return total_models, total_violations, all_output


def main():
    print("=" * 60)
    print("  dbt Layering Standards Validator")
    print("=" * 60)
    print()

    if not MODELS_DIR.exists():
        print(f"❌ Models directory not found: {MODELS_DIR}")
        sys.exit(1)

    total_models, total_violations, output = scan_models()

    if output:
        print("VIOLATIONS FOUND:")
        print("\n".join(output))
        print()

    print("-" * 60)
    print(f"  Models scanned: {total_models}")
    print(f"  Violations:     {total_violations}")
    print("-" * 60)

    if total_violations > 0:
        print("\n❌ FAILED — Fix the above violations before pushing.")
        print("   See DBT_LAYERING_STANDARDS.md for full rules.")
        sys.exit(1)
    else:
        print("\n✅ PASSED — All models follow layering standards.")
        sys.exit(0)


if __name__ == "__main__":
    main()

