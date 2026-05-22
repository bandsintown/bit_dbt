#!/usr/bin/env bash

set -euo pipefail

# MWAA syncs from S3 dags/ into this local path.
DEFAULT_PROJECT_DIR="/usr/local/airflow/dags/dependencies/dbt/project"
PROJECT_DIR="${DBT_PROJECT_DIR:-$DEFAULT_PROJECT_DIR}"
PROFILES_DIR="${DBT_PROFILES_DIR:-$PROJECT_DIR}"
DBT_TARGET="${DBT_TARGET:-prod}"

usage() {
  cat <<EOF
Usage: ./scripts/run_dbt.sh <dbt-command> [extra-args...]

Examples:
  ./scripts/run_dbt.sh run
  ./scripts/run_dbt.sh test
  ./scripts/run_dbt.sh build --select tag:daily

Environment overrides:
  DBT_PROJECT_DIR   (default: $DEFAULT_PROJECT_DIR)
  DBT_PROFILES_DIR  (default: DBT_PROJECT_DIR)
  DBT_TARGET        (default: prod)
EOF
}

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

DBT_COMMAND="$1"
shift

if ! command -v dbt >/dev/null 2>&1; then
  echo "[ERROR] dbt CLI not found in PATH." >&2
  exit 1
fi

if [ ! -d "$PROJECT_DIR" ]; then
  echo "[ERROR] DBT project directory does not exist: $PROJECT_DIR" >&2
  exit 1
fi

echo "DBT_COMMAND=$DBT_COMMAND"
echo "DBT_PROJECT_DIR=$PROJECT_DIR"
echo "DBT_PROFILES_DIR=$PROFILES_DIR"
echo "DBT_TARGET=$DBT_TARGET"

dbt "$DBT_COMMAND" \
  --project-dir "$PROJECT_DIR" \
  --profiles-dir "$PROFILES_DIR" \
  --target "$DBT_TARGET" \
  "$@"

