"""
Advanced Airflow DAG using dbt-Cosmos for automatic task generation.
"""

import os
from datetime import datetime, timedelta
from cosmos import (
    DbtDag,
    ExecutionConfig,
    ExecutionMode,
    LoadMode,
    ProfileConfig,
    ProjectConfig,
    RenderConfig,
)
from cosmos.constants import TestBehavior


# -----------------------------
# CALLBACKS
# -----------------------------
def on_task_failure(context):
    """Called when any task in the DAG fails."""
    dag_id = context["dag"].dag_id
    print(f"[FAILURE] DAG={dag_id} execution_date={context['execution_date']}")
    # Add custom logic here: Slack webhook, PagerDuty, etc.


def on_dag_failure(context):
    """Called when the entire DAG run fails."""
    print(f"[DAG FAILURE] DAG={context['dag'].dag_id} run_id={context['run_id']}")


# -----------------------------
# CONFIG
# -----------------------------

DBT_PROJECT_LOCAL_PATH = "/usr/local/airflow/dags/dependencies/dbt/project"
DBT_PROFILE_FILE_NAME = "profiles.yml"

DBT_VENV_REQUIREMENTS = [
    "dbt-core==1.7.13",
    "dbt-athena-community==1.7.2",
]

DBT_MANIFEST_PATH = os.path.join(DBT_PROJECT_LOCAL_PATH, "target", "manifest.json")
DBT_PROFILES_PATH = os.path.join(DBT_PROJECT_LOCAL_PATH, DBT_PROFILE_FILE_NAME)


# -----------------------------
# DEFAULTS
# -----------------------------
default_args = {
    "owner": "data-engineering",
    "depends_on_past": False,
    "email": ["data-alerts@bandsintown.com"],
    "email_on_failure": True,
    "email_on_retry": False,
    "retries": 0,
    "retry_delay": timedelta(minutes=5),
    "on_failure_callback": on_task_failure,
}


# -----------------------------
# DBT COSMOS DAG
# -----------------------------
dbt_cosmos_dag = DbtDag(
    dag_id="dbt_feature_events_cosmos",

    project_config=ProjectConfig(
        project_name="bandsintown",
        manifest_path=DBT_MANIFEST_PATH,
    ),

    render_config=RenderConfig(
        load_method=LoadMode.DBT_MANIFEST,
        test_behavior=TestBehavior.NONE,
        select=["path:models/feature_events"],
    ),

    execution_config=ExecutionConfig(
        execution_mode=ExecutionMode.VIRTUALENV,
        dbt_project_path=DBT_PROJECT_LOCAL_PATH,
    ),

    profile_config=ProfileConfig(
        profile_name="bandsintown",
        target_name="prod",
        profiles_yml_filepath=DBT_PROFILES_PATH,
    ),

    operator_args={
        "install_deps": True,
        "py_requirements": DBT_VENV_REQUIREMENTS,
        "py_system_site_packages": False,
        "env": {
            "AWS_REGION": "us-east-1",
            "DBT_TARGET": "{{ params.dbt_target }}",
            "DBT_PROJECT_DIR": DBT_PROJECT_LOCAL_PATH,
            "DBT_ATHENA_DATABASE": "{{ params.dbt_athena_database }}",
            "DBT_ATHENA_WORKGROUP": "{{ params.dbt_athena_workgroup }}",
            "DBT_ATHENA_S3_STAGING_DIR": "{{ params.dbt_athena_s3_staging }}",
        },
    },

    params={
        "dbt_target": "prod",
        "dbt_athena_workgroup": "primary",
        "dbt_athena_database": "bit_dbt_prod",
        "dbt_athena_s3_staging": "s3://bit-dbt-prod/bit_dbt/prod/",
    },

    default_args=default_args,
    start_date=datetime(2026, 1, 1),
    schedule="0 2 * * *",
    catchup=False,
    max_active_runs=1,
    tags=["dbt", "athena", "feature_events", "cosmos"],
    on_failure_callback=on_dag_failure,
)
