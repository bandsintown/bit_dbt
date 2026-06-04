# Copilot Instructions for bit-dbt

## MANDATORY: dbt Layering Validation

**Before making ANY changes to files under `models/`, you MUST validate the 3-layer hierarchy.**

### Layer Rules (STRICT — no exceptions)

1. **Staging (`models/staging/stg_*`)**
   - Reads from: `{{ source() }}` ONLY
   - Only `SELECT` + `CAST` + column renaming + basic `WHERE` for filtering junk
   - NO complex JOINs, GROUP BY, aggregations

2. **Intermediate (`models/intermediate/int_*`)**
   - Reads from: `{{ ref('stg_...') }}` ONLY
   - CANNOT reference dims, facts, marts, or source()
   - Handles: joins across staging models, UNION ALL, window functions, pivots, reshaping

3. **Marts / Core (`models/marts/*/dim_*`, `fct_*`, `mart_*`)**
   - `dim_*` reads from: `{{ ref('stg_...') }}`, `{{ ref('int_...') }}`, other `{{ ref('dim_...') }}`
   - `fct_*` reads from: `{{ ref('stg_...') }}`, `{{ ref('int_...') }}`, `{{ ref('dim_...') }}`, other `{{ ref('fct_...') }}`
   - `mart_*` reads from: `{{ ref('fct_...') }}`, `{{ ref('dim_...') }}`
   - CANNOT reference `{{ source() }}`

### Dependency flow

```
sources → stg_ → int_ → dim_/fct_/mart_
```

### If you are about to create or edit a model:

1. Identify which layer it belongs to based on its prefix and location
2. Check that all `ref()` calls point to allowed layers only
3. Check that no forbidden SQL operations exist for that layer

**DO NOT suggest or implement code that violates these rules.**
