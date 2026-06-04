# AGENTS.md

## Project Overview

dbt project for **Bandsintown** analytics on **AWS Athena** (Presto/Trino dialect), S3-backed Parquet/Snappy data. Orchestrated via Airflow (MWAA), infra managed by Serverless Framework.

## Architecture

```
sources (Glue/Athena) → stg_ (view) → int_ (view) → dim_/fct_/mart_ (table)
```

- **Adapter**: `dbt-athena-community` — use `CAST()` not `::`, `varchar` not `text`
- **Profiles**: `--profiles-dir .` (repo root `profiles.yml`), env var `DBT_TARGET=dev|staging|prod`
- **Schema routing**: `macros/generate_schema_name.sql`

## Layering Rules (3-Layer)

| Layer | Prefix | Reads from | Forbidden |
|-------|--------|-----------|-----------|
| Staging | `stg_*` | `source()` only | complex JOINs, GROUP BY, aggregations |
| Intermediate | `int_*` | `ref('stg_...')` only | dims, facts, marts, source() |
| Marts | `dim_*`, `fct_*`, `mart_*` | `ref('stg_...')`, `ref('int_...')`, `ref('dim_...')`, `ref('fct_...')` | source() |

**Dependency flow:** `sources → stg_ → int_ → dim_/fct_/mart_`

See `.agent/DBT_LAYERING_STANDARDS.md` for full rules and examples.

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
- **Staging**: SELECT + CAST + rename + basic filtering. One model per source table. Materialized as `view`.
- **Intermediate**: Joins, unions, window functions across staging models. Materialized as `view`.
- **Dims/Facts/Marts**: Denormalized presentation-layer tables. Materialized as `table` with `format: parquet`, `write_compression: snappy`.

## File Structure

```
models/staging/<domain>/     — stg_ views + _sources.yml
models/intermediate/         — int_ views (cross-staging reshaping)
models/marts/<domain>/       — dim_, fct_, mart_ tables (grouped by domain)
macros/                      — shared SQL macros
dags/                        — Airflow DAGs for MWAA
environment/                 — Serverless Framework IaC
scripts/                     — deploy, validate, setup scripts
```

## Deployment

- `scripts/deploy.sh` — deploys Serverless infra
- `scripts/upload_dbt_payload.py` — uploads compiled dbt artifacts to S3
- `dags/dbt_marts_core.py` — Airflow DAG that runs dbt in MWAA
