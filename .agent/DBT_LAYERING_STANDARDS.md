# dbt Layering & Hierarchy Standards

> **This document defines the mandatory layering rules for all dbt models in this project.**
> Before pushing any changes, all models must be validated against these standards.

---

## Layer Hierarchy

```
Sources (raw tables in Glue/Athena)
    ↓
Staging (stg_*)
    ↓
Dimensions (dim_*)
    ↓
Intermediate (int_*)
    ↓
Facts (fct_*)
    ↓
Marts (mart_*)
```

---

## Rules Per Layer

### 1. Staging (`models/staging/`)

| Rule | Description |
|------|-------------|
| Reads from | **Sources only** (`{{ source(...) }}`) |
| Materialization | `view` |
| Allowed operations | `SELECT`, `CAST`, column renaming |
| **NOT allowed** | `WHERE`, `JOIN`, `GROUP BY`, `HAVING`, `WINDOW`, `UNION`, business logic, filtering, deduplication, coalesce with defaults |
| Naming | `stg_<domain>_<entity>.sql` |
| One-to-one | Each staging model maps to exactly one source table |

**Example (correct):**
```sql
select
    cast(artist_event_int_id as integer) as artist_event_int_id,
    cast(ds as date) as ds,
    cast(fe_source as varchar) as fe_source,
    cast(user_id as integer) as user_id
from {{ source('featured_events', 'pixelactivities') }}
```

**Example (WRONG — has WHERE):**
```sql
select ...
from {{ source('featured_events', 'pixelactivities') }}
where nonce is not null  -- ❌ filtering belongs in dim or intermediate
```

---

### 2. Dimensions (`models/marts/<domain>/dim_*`)

| Rule | Description |
|------|-------------|
| Reads from | **Staging only** (`{{ ref('stg_...') }}`) |
| Materialization | `table` |
| Allowed operations | Filtering (`WHERE`), deduplication (`ROW_NUMBER`), null checks, type coercion |
| Purpose | One row per entity (deduplicated, clean, filtered master data) |
| Naming | `dim_<entity>.sql` |

**Example:**
```sql
with deduped as (
    select *, row_number() over (partition by nonce order by ds desc) as row_num
    from {{ ref('stg_featured_events_rsvps') }}
    where nonce is not null and artist_event_int_id is not null
)
select ... from deduped where row_num = 1
```

---

### 3. Intermediate (`models/intermediate/`)

| Rule | Description |
|------|-------------|
| Reads from | **Dimensions** (`{{ ref('dim_...') }}`) or **Staging** (only if no dim exists for that entity) |
| Materialization | `view` |
| Allowed operations | `UNION ALL`, `JOIN`, pivots, reshaping, window functions for combining data |
| **NOT allowed** | Filtering that should be in dims (null checks, validity, dedup) |
| Purpose | Combine/reshape cleaned data from multiple dims into a unified schema |
| Naming | `int_<description>.sql` |

**Example:**
```sql
select ... from {{ ref('dim_featured_events_pixel_impressions') }}
union all
select ... from {{ ref('dim_featured_events_email_impressions') }}
```

---

### 4. Facts (`models/marts/<domain>/fct_*`)

| Rule | Description |
|------|-------------|
| Reads from | **Dimensions** and/or **Intermediate** (`{{ ref('dim_...') }}`, `{{ ref('int_...') }}`) |
| Materialization | `table` |
| Allowed operations | Joins between dims/intermediate, grain-level event recording, aggregation per grain |
| **NOT allowed** | Reading directly from staging, raw filtering that should be in dims |
| Purpose | One row per event/transaction at the defined grain |
| Naming | `fct_<entity>_<grain>.sql` |

---

### 5. Marts (`models/marts/<domain>/mart_*`)

| Rule | Description |
|------|-------------|
| Reads from | **Facts** and/or **Dimensions** (`{{ ref('fct_...') }}`, `{{ ref('dim_...') }}`) |
| Materialization | `table` |
| Allowed operations | Aggregation, rollups, summaries for end-user consumption |
| **NOT allowed** | Reading from staging or intermediate |
| Purpose | Pre-aggregated summaries optimized for BI/reporting |
| Naming | `mart_<description>.sql` |

---

## Dependency Flow (what can reference what)

| Layer | Can reference |
|-------|--------------|
| `stg_*` | sources only |
| `dim_*` | `stg_*` only |
| `int_*` | `dim_*` (preferred), `stg_*` (only if no dim exists) |
| `fct_*` | `dim_*`, `int_*`, other `fct_*` |
| `mart_*` | `fct_*`, `dim_*` |

**Never allowed:**
- ❌ `fct_*` → `stg_*`
- ❌ `mart_*` → `stg_*`
- ❌ `mart_*` → `int_*`
- ❌ `dim_*` → `dim_*` (no dim-to-dim references)
- ❌ `stg_*` → anything other than sources

---

## Pre-Push Checklist

Before pushing any model changes, verify:

- [ ] **Staging models** have NO `WHERE`, `JOIN`, `GROUP BY`, or business logic
- [ ] **Dimensions** read ONLY from staging
- [ ] **Intermediate** reads from dimensions (or staging if no dim exists)
- [ ] **Facts** read from dimensions/intermediate — NOT from staging
- [ ] **Marts** read from facts/dimensions — NOT from staging or intermediate
- [ ] **No circular dependencies** exist
- [ ] **Model naming** follows `stg_`, `dim_`, `int_`, `fct_`, `mart_` prefixes
- [ ] **Materialization** is correct: staging/intermediate = `view`, dims/facts/marts = `table`
- [ ] **`dbt compile`** succeeds without errors

---

## File Structure

```
models/
  staging/
    <domain>/
      _sources.yml
      stg_<domain>_<entity>.sql
  intermediate/
    int_<description>.sql
  marts/
    <domain>/
      dim_<entity>.sql
      fct_<entity>.sql
      mart_<description>.sql
```

