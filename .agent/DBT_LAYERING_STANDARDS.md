# dbt Layering & Hierarchy Standards

> **This document defines the mandatory layering rules for all dbt models in this project.**

---

## Layer Hierarchy (3-Layer Architecture)

```
Sources (raw tables in Glue/Athena)
    ↓
Staging (stg_*)
    ↓
Intermediate (int_*)
    ↓
Marts / Core (dim_*, fct_*, mart_*)
```

---

## Rules Per Layer

### 1. Staging (`models/staging/`)

| Rule | Description |
|------|-------------|
| Reads from | **Sources only** (`{{ source(...) }}`) |
| Materialization | `view` |
| Purpose | 1-to-1 mapping with raw source tables. Standardize column names, cast data types, filter irrelevant records, add surrogate keys |
| Allowed operations | `SELECT`, `CAST`, column renaming, basic `WHERE` to filter junk/irrelevant records, surrogate key generation |
| **NOT allowed** | Complex `JOIN`s, `GROUP BY`, aggregations |
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

---

### 2. Intermediate (`models/intermediate/`)

| Rule | Description |
|------|-------------|
| Reads from | **Staging only** (`{{ ref('stg_...') }}`) |
| Materialization | `view` (or `table` if the dataset is massive) |
| Purpose | Complex business logic to prepare data for the presentation layer. Join multiple staging models, pivot data, apply window functions, compute row-level metrics |
| Allowed operations | `JOIN`, `UNION ALL`, `GROUP BY`, window functions (`ROW_NUMBER`, `OVER()`), pivots, reshaping, deduplication, null filtering |
| Note | Business users rarely query this layer directly; it is a building block for marts |
| Naming | `int_<description>.sql` |

**Example:**
```sql
select ... from {{ ref('stg_featured_events_pixel_impressions') }}
union all
select ... from {{ ref('stg_featured_events_email_impressions') }}
```

---

### 3. Marts / Core (`models/marts/<domain>/`)

This is the **presentation layer** — the "public API" for BI tools and analysts.

#### Dimensions (`dim_*`)

| Rule | Description |
|------|-------------|
| Reads from | `{{ ref('stg_...') }}`, `{{ ref('int_...') }}`, other `{{ ref('dim_...') }}` |
| Materialization | `table` |
| Purpose | One row per entity — deduplicated, clean master data |

#### Facts (`fct_*`)

| Rule | Description |
|------|-------------|
| Reads from | `{{ ref('int_...') }}`, `{{ ref('dim_...') }}`, `{{ ref('stg_...') }}`, other `{{ ref('fct_...') }}` |
| Materialization | `table` |
| Purpose | One row per event/transaction at the defined grain |

#### Marts (`mart_*`)

| Rule | Description |
|------|-------------|
| Reads from | `{{ ref('fct_...') }}`, `{{ ref('dim_...') }}` |
| Materialization | `table` |
| Purpose | Pre-aggregated summaries optimized for BI/reporting |

---

## Dependency Flow (what can reference what)

| Layer | Can reference |
|-------|--------------|
| `stg_*` | `source()` only |
| `int_*` | `stg_*` only |
| `dim_*` | `stg_*`, `int_*`, other `dim_*` |
| `fct_*` | `stg_*`, `int_*`, `dim_*`, other `fct_*` |
| `mart_*` | `fct_*`, `dim_*` |

**Never allowed:**
- ❌ `stg_*` → anything other than sources
- ❌ `int_*` → `dim_*`, `fct_*`, `mart_*`
- ❌ `mart_*` → `stg_*`, `int_*`

---

## Pre-Push Checklist

- [ ] **Staging models** have NO complex JOINs or aggregations
- [ ] **Intermediate** reads ONLY from staging
- [ ] **Dims/Facts** read from staging, intermediate, or other marts — NOT from sources
- [ ] **Marts** read from facts/dims — NOT from staging or intermediate
- [ ] **No circular dependencies** exist
- [ ] **Model naming** follows `stg_`, `int_`, `dim_`, `fct_`, `mart_` prefixes
- [ ] **Materialization** is correct: staging/intermediate = `view`, marts = `table`
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
