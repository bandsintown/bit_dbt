# Copilot Instructions for bit-dbt

## MANDATORY: dbt Layering Validation

**Before making ANY changes to files under `models/`, you MUST validate the layering hierarchy.**

### Layer Rules (STRICT — no exceptions)

1. **Staging (`models/staging/stg_*`)**
   - Reads from: `{{ source() }}` ONLY
   - NO `WHERE`, `JOIN`, `GROUP BY`, `UNION`, `OVER()`, `COALESCE` with defaults
   - Only `SELECT` + `CAST` + column renaming

2. **Dimensions (`models/marts/*/dim_*`)**
   - Reads from: `{{ ref('stg_...') }}` ONLY
   - NO dim-to-dim references
   - NO source() calls
   - Handles: filtering, deduplication, null checks

3. **Intermediate (`models/intermediate/int_*`)**
   - Reads from: `{{ ref('dim_...') }}` (preferred) or `{{ ref('stg_...') }}` if no dim exists
   - CANNOT reference facts or marts
   - Handles: unions, reshaping, combining dims

4. **Facts (`models/marts/*/fct_*`)**
   - Reads from: `{{ ref('dim_...') }}`, `{{ ref('int_...') }}`, other `{{ ref('fct_...') }}`
   - CANNOT reference staging directly
   - CANNOT reference marts

5. **Marts (`models/marts/*/mart_*`)**
   - Reads from: `{{ ref('fct_...') }}`, `{{ ref('dim_...') }}`
   - CANNOT reference staging or intermediate

### Pre-push validation

Always run `python3 scripts/validate_layering.py` after editing models to verify compliance.

### Dependency flow

```
sources → stg_ → dim_ → int_ → fct_ → mart_
```

### If you are about to create or edit a model:

1. Identify which layer it belongs to based on its prefix and location
2. Check that all `ref()` calls point to allowed layers only
3. Check that no forbidden SQL operations exist for that layer
4. Run the validator mentally or suggest running it

**DO NOT suggest or implement code that violates these rules.**

