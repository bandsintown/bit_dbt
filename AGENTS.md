# AGENTS.md

## Project Overview

dbt project for **Bandsintown** analytics on **AWS Athena** (Presto/Trino dialect), S3-backed Parquet/Snappy data. Orchestrated via Airflow (MWAA), infra managed by Serverless Framework.

## Architecture

```
sources (Glue/Athena) → stg_ (view) → dim_ (table) → int_ (view) → fct_ (table) → mart_ (table)
```

- **Adapter**: `dbt-athena-community` — use `CAST()` not `::`, `varchar` not `text`
- **Profiles**: `--profiles-dir .` (repo root `profiles.yml`), env var `DBT_TARGET=dev|staging|prod`
- **Schema routing**: `macros/generate_schema_name.sql`

## Layering Rules (STRICT — enforced by `scripts/validate_layering.py`)

| Layer | Prefix | Reads from | Forbidden |
|-------|--------|-----------|-----------|
| Staging | `stg_*` | `source()` only | WHERE, JOIN, GROUP BY, UNION, OVER(), COALESCE |
| Dimension | `dim_*` | `ref('stg_...')` only | source(), other dims |
| Intermediate | `int_*` | `ref('dim_...')` preferred | facts, marts |
| Fact | `fct_*` | dims, intermediates, other facts | staging, source() |
| Mart | `mart_*` | facts, dims | staging, intermediate, source() |

**After ANY model edit, run:** `python3 scripts/validate_layering.py`

## Key Commands

```bash
make setup              # Dev environment setup
make run                # Run all models (dev target)
make run-model MODEL=x  # Single model
make lint               # sqlfluff (athena dialect)
make lint-fix           # Auto-fix SQL
make test               # dbt tests
make compile            # Compile without executing
```

## Conventions

- **Model configs**: Always include `materialized` and `tags` in `{{ config() }}`
- **Sources**: `_sources.yml` colocated in `models/staging/<domain>/`
- **Macros**: Reuse `macros/cents_to_dollars.sql` and `macros/union_tables.sql` before writing inline logic
- **Staging**: Only SELECT + CAST + rename. One model per source table.
- **Dimensions**: Deduplication (`ROW_NUMBER`), null filtering, one row per entity
- **Intermediate**: UNION ALL across dims, reshaping for facts
- **Materializations**: staging/intermediate = `view`; dims/facts/marts = `table` with `format: parquet`, `write_compression: snappy`

## File Structure

```
models/staging/<domain>/     — stg_ views + _sources.yml
models/marts/<domain>/       — dim_, fct_, mart_ (grouped by domain)
models/intermediate/         — int_ cross-domain reshaping
macros/                      — shared SQL macros
dags/                        — Airflow DAGs for MWAA
environment/                 — Serverless Framework IaC
scripts/                     — deploy, validate, setup scripts
```

## Deployment

- `scripts/deploy.sh` — deploys Serverless infra
- `scripts/upload_dbt_payload.py` — uploads compiled dbt artifacts to S3
- `dags/dbt_marts_core.py` — Airflow DAG that runs dbt in MWAA
