"""
DAG: dbt marts/core models.
First runs staging+intermediate, then feature_events marts, then core marts.
Uses TriggerDagRunOperator to chain sub-DAGs in sequence.
"""

import os
from datetime import datetime, timedelta

from airflow import DAG
from cosmos import (
    DbtTaskGroup,
    ExecutionConfig,
    ExecutionMode,
    LoadMode,
    ProfileConfig,
    ProjectConfig,
    RenderConfig,
)
from cosmos.constants import TestBehavior
from cosmos.operators.virtualenv import DbtSeedVirtualenvOperator

DBT_PROJECT_LOCAL_PATH = "/usr/local/airflow/dags/dependencies/dbt/project"
DBT_MANIFEST_PATH = os.path.join(DBT_PROJECT_LOCAL_PATH, "target", "manifest.json")
DBT_PROFILES_PATH = os.path.join(DBT_PROJECT_LOCAL_PATH, "profiles.yml")

DBT_VENV_REQUIREMENTS = [
    "dbt-core==1.7.13",
    "dbt-athena-community==1.7.2",
]

default_args = {
    "owner": "data-engineering",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="dbt_marts_core",
    default_args=default_args,
    start_date=datetime(2026, 1, 1),
    schedule="0 2 * * *",
    catchup=False,
    max_active_runs=1,
    tags=["dbt", "athena", "core", "marts", "cosmos"],
) as dag:

    common_config = dict(
        project_config=ProjectConfig(
            project_name="bandsintown",
            manifest_path=DBT_MANIFEST_PATH,
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
        },
    )

    seed = DbtSeedVirtualenvOperator(
        task_id="dbt_seed",
        project_dir=DBT_PROJECT_LOCAL_PATH,
        profile_config=ProfileConfig(
            profile_name="bandsintown",
            target_name="prod",
            profiles_yml_filepath=DBT_PROFILES_PATH,
        ),
        install_deps=True,
        py_requirements=DBT_VENV_REQUIREMENTS,
        py_system_site_packages=False,
    )

    staging_intermediate = DbtTaskGroup(
        group_id="staging_intermediate",
        render_config=RenderConfig(
            load_method=LoadMode.DBT_MANIFEST,
            test_behavior=TestBehavior.NONE,
            select=["path:models/staging", "path:models/intermediate"],
        ),
        **common_config,
    )

    marts_feature_events = DbtTaskGroup(
        group_id="marts_feature_events",
        render_config=RenderConfig(
            load_method=LoadMode.DBT_MANIFEST,
            test_behavior=TestBehavior.NONE,
            select=["path:models/marts/feature_events"],
        ),
        **common_config,
    )

    seed >> staging_intermediate >> marts_feature_events

