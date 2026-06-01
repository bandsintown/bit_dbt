"""
Airflow DAG using Astronomer Cosmos to orchestrate dbt models.

Cosmos auto-generates one Airflow task per dbt model from
the project manifest, preserving dbt's dependency graph.

Requirements (add to MWAA requirements.txt):
  astronomer-cosmos==1.5.0

  dbt is installed at runtime in an isolated virtualenv by Cosmos.
  No dbt packages needed in MWAA requirements (avoids constraint conflicts).

Airflow Variables to set:
  dbt_target          dev | staging | prod (default: prod)
  dbt_athena_workgroup  Athena workgroup (default: primary)
  dbt_athena_database   Glue database    (default: bit_dbt_prod)
  dbt_athena_s3_staging S3 staging path  (default: s3://bit-dbt-prod/bit_dbt/prod/)
"""

from datetime import datetime, timedelta
from pathlib import Path

from airflow import DAG
from airflow.models import Variable

from cosmos import DbtDag, ProjectConfig, ProfileConfig, ExecutionConfig, RenderConfig
from cosmos.profiles import AthenaProfileMapping
from cosmos.constants import ExecutionMode, TestBehavior

# ── paths (MWAA syncs S3 dags/ → /usr/local/airflow/dags/) ──────────────────
DBT_PROJECT_DIR  = Path("/usr/local/airflow/dags/dependencies/dbt/project")
DBT_PROFILES_DIR = DBT_PROJECT_DIR
DBT_MANIFEST     = DBT_PROJECT_DIR / "target" / "manifest.json"

# ── runtime config ────────────────────────────────────────────────────────────
DBT_TARGET          = Variable.get("dbt_target",           default_var="prod")
ATHENA_WORKGROUP    = Variable.get("dbt_athena_workgroup", default_var="primary")
ATHENA_DATABASE     = Variable.get("dbt_athena_database",  default_var=f"bit_dbt_{DBT_TARGET}")
ATHENA_S3_STAGING   = Variable.get(
    "dbt_athena_s3_staging",
    default_var=f"s3://bit-dbt-{DBT_TARGET}/bit_dbt/{DBT_TARGET}/",
)
AWS_REGION = Variable.get("aws_region", default_var="us-east-1")

# ── Cosmos configs ────────────────────────────────────────────────────────────
project_config = ProjectConfig(
    dbt_project_path=DBT_PROJECT_DIR,
    manifest_path=DBT_MANIFEST,
    project_name="bandsintown",
)

profile_config = ProfileConfig(
    profile_name="bandsintown",
    target_name=DBT_TARGET,
    profile_mapping=AthenaProfileMapping(
        conn_id="aws_default",
        profile_args={
            "s3_staging_dir": ATHENA_S3_STAGING,
            "region_name": AWS_REGION,
            "database": "awsdatacatalog",
            "schema": ATHENA_DATABASE,
            "work_group": ATHENA_WORKGROUP,
        },
    ),
)

execution_config = ExecutionConfig(
    execution_mode=ExecutionMode.VIRTUALENV,
    dbt_executable_path="dbt",
    virtualenv_dir="/tmp/dbt_venv",
    py_requirements=[
        "dbt-core==1.7.13",
        "dbt-athena-community==1.7.2",
    ],
)

render_config = RenderConfig(
    select=["path:models/feature_events"],     # scope to feature_events models
    test_behavior=TestBehavior.AFTER_EACH,     # run dbt test after each model
)

# ── DAG ───────────────────────────────────────────────────────────────────────
dag = DbtDag(
    dag_id="dbt_feature_events_cosmos",
    description="Cosmos-managed dbt DAG for feature_events models",
    schedule_interval="0 2 * * *",          # 2 AM UTC daily
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    default_args={
        "owner": "data-engineering",
        "retries": 2,
        "retry_delay": timedelta(minutes=5),
        "email_on_failure": True,
    },
    tags=["dbt", "cosmos", "feature_events", "athena"],
    project_config=project_config,
    profile_config=profile_config,
    execution_config=execution_config,
    render_config=render_config,
)

