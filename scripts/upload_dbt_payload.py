#!/usr/bin/env python3
"""Upload dbt runtime payload to S3 using boto3 (no sync/list operations)."""

from __future__ import annotations

import argparse
import fnmatch
from pathlib import Path
from typing import Iterable, List

import boto3
from botocore.exceptions import ProfileNotFound

EXCLUDE_PATTERNS = [
    ".git/*",
    ".github/*",
    ".buildkite/*",
    ".idea/*",
    ".venv/*",
    "target/*",
    "logs/*",
    "dbt_packages/*",
    "node_modules/*",
    "environment/*",
    "scripts/*",
    "dags/*",
]

INCLUDE_PATHS = {
    "target/manifest.json",
}

# Only these top-level directories/files are uploaded as the dbt project payload
PROJECT_ALLOWED_PREFIXES = [
    "models/",
    "macros/",
    "seeds/",
    "snapshots/",
]

PROJECT_ALLOWED_FILES = {
    "dbt_project.yml",
    "profiles.yml",
}


def is_excluded(relative_path: str, patterns: Iterable[str]) -> bool:
    return any(fnmatch.fnmatch(relative_path, pattern) for pattern in patterns)


def iter_files(base_dir: Path, exclude_patterns: Iterable[str]) -> Iterable[Path]:
    for path in base_dir.rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(base_dir).as_posix()
        if is_excluded(rel, exclude_patterns):
            continue
        yield path


def iter_project_files(base_dir: Path) -> Iterable[Path]:
    for path in base_dir.rglob("*"):
        if not path.is_file():
            continue
        rel = path.relative_to(base_dir).as_posix()
        # Always include explicit paths like target/manifest.json
        if rel in INCLUDE_PATHS:
            yield path
            continue
        # Skip READMEs and .env files
        if path.name.lower().startswith("readme") or path.name == ".env":
            continue
        # Allow only specific top-level files
        if rel in PROJECT_ALLOWED_FILES:
            yield path
            continue
        # Allow only specific directory prefixes
        if any(rel.startswith(prefix) for prefix in PROJECT_ALLOWED_PREFIXES):
            yield path
            continue
        # Everything else is excluded


def upload_files(bucket, root_dir: Path, files: Iterable[Path], key_prefix: str, dry_run: bool) -> int:
    count = 0
    normalized_prefix = key_prefix.strip("/")
    for file_path in files:
        rel = file_path.relative_to(root_dir).as_posix()
        key = f"{normalized_prefix}/{rel}" if normalized_prefix else rel
        print(f"- {file_path} -> s3://{bucket.name}/{key}")
        if not dry_run:
            bucket.upload_file(Filename=str(file_path), Key=key)
        count += 1
    return count


def build_session(profile: str, region: str):
    try:
        return boto3.Session(profile_name=profile, region_name=region)
    except ProfileNotFound as exc:
        raise SystemExit(f"[ERROR] AWS profile '{profile}' not found: {exc}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Upload dbt scripts + project payload to S3.")
    parser.add_argument("--bucket", required=True, help="Target S3 bucket name")
    parser.add_argument("--scripts-prefix", default="dags/dependencies/dbt/scripts", help="S3 key prefix for scripts/")
    parser.add_argument("--project-prefix", default="dags/dependencies/dbt/project", help="S3 key prefix for dbt project payload")
    parser.add_argument("--profile", default="bit-prod", help="AWS profile name (default: bit-prod)")
    parser.add_argument("--region", default="us-east-1", help="AWS region")
    parser.add_argument("--root", default=".", help="Repository root directory")
    parser.add_argument("--dry-run", action="store_true", help="Print planned uploads without writing to S3")
    args = parser.parse_args()

    root_dir = Path(args.root).resolve()
    scripts_dir = root_dir / "scripts"

    if not scripts_dir.is_dir():
        raise SystemExit(f"[ERROR] scripts directory not found: {scripts_dir}")

    session = build_session(args.profile, args.region)
    bucket = session.resource("s3").Bucket(args.bucket)

    print(f"Using profile={args.profile} region={args.region}")
    print(f"Uploading scripts/ to s3://{args.bucket}/{args.scripts_prefix.strip('/')}/")
    script_files = list(iter_files(scripts_dir, exclude_patterns=[]))
    scripts_uploaded = upload_files(bucket, scripts_dir, script_files, args.scripts_prefix, args.dry_run)

    print(f"Uploading dbt payload to s3://{args.bucket}/{args.project_prefix.strip('/')}/")
    project_files = list(iter_project_files(root_dir))
    project_uploaded = upload_files(bucket, root_dir, project_files, args.project_prefix, args.dry_run)

    # Upload dags/ folder (DAG Python files) to bucket dags/
    dags_dir = root_dir / "dags"
    dags_uploaded = 0
    if dags_dir.is_dir():
        print(f"Uploading dags/ to s3://{args.bucket}/dags/")
        dag_files = list(iter_files(dags_dir, exclude_patterns=["requirements.txt"]))
        dags_uploaded = upload_files(bucket, dags_dir, dag_files, "dags", args.dry_run)

    # Upload requirements.txt to bucket root (MWAA reads it from RequirementsS3Path)
    req_file = dags_dir / "requirements.txt"
    if req_file.is_file():
        print(f"Uploading requirements.txt to s3://{args.bucket}/requirements.txt")
        if not args.dry_run:
            bucket.upload_file(Filename=str(req_file), Key="requirements.txt")

    print(f"Completed: scripts={scripts_uploaded}, project={project_uploaded}, dags={dags_uploaded}, dry_run={args.dry_run}")


if __name__ == "__main__":
    main()

