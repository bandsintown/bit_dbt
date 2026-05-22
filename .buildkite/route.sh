#!/bin/bash
set -euo pipefail

DEPLOY_PATH=$(buildkite-agent meta-data get deploy_path)
ENVIRONMENT=$(buildkite-agent meta-data get environment)

echo "--- :buildkite: Routing deployment"
echo "Path:        $DEPLOY_PATH"
echo "Environment: $ENVIRONMENT"

if [ "$DEPLOY_PATH" = "upload_s3" ]; then
  echo "--- :aws: Uploading pipeline for S3 upload"
  DAG_BUCKET="${{DAG_SCRIPTS_BUCKET:-bit-dbt-${ENVIRONMENT}}}"
  SCRIPTS_PREFIX="${DAG_SCRIPTS_PREFIX:-dags/dependencies/dbt/scripts}"
  DBT_PROJECT_PREFIX="${DBT_PROJECT_S3_PREFIX:-dags/dependencies/dbt/project}"

  echo "S3 bucket:     $DAG_BUCKET"
  echo "Scripts prefix: $SCRIPTS_PREFIX"
  echo "Project prefix: $DBT_PROJECT_PREFIX"

  buildkite-agent pipeline upload <<EOF
steps:
  - label: ":aws: Upload dbt payload to S3 (${ENVIRONMENT})"
    key: "upload-scripts-s3"
    commands:
      - set -euo pipefail
      - 'echo "Syncing scripts/ to s3://${DAG_BUCKET}/${SCRIPTS_PREFIX}/"; aws s3 sync scripts/ "s3://${DAG_BUCKET}/${SCRIPTS_PREFIX}/" --delete --exact-timestamps; echo "Syncing dbt project payload to s3://${DAG_BUCKET}/${DBT_PROJECT_PREFIX}/"; aws s3 sync . "s3://${DAG_BUCKET}/${DBT_PROJECT_PREFIX}/" --delete --exact-timestamps --exclude ".git/*" --exclude ".github/*" --exclude ".buildkite/*" --exclude ".idea/*" --exclude ".venv/*" --exclude "target/*" --exclude "logs/*" --exclude "dbt_packages/*" --exclude "node_modules/*" --exclude "environment/*" --exclude "scripts/*"; echo "Done"'
EOF

elif [ "$DEPLOY_PATH" = "serverless_permissions" ]; then
  echo "--- :serverless: Uploading pipeline for Serverless permissions"
  buildkite-agent pipeline upload <<EOF
steps:
  - label: ":serverless: Deploy Serverless permissions (${ENVIRONMENT})"
    key: "deploy-serverless-permissions"
    commands:
      - set -euo pipefail
      - 'echo "Deploying serverless permissions to environment: ${ENVIRONMENT}"'
      - './scripts/deploy_permissions.sh "${ENVIRONMENT}" "\${AWS_PROFILE:-}" "\${AWS_REGION:-us-east-1}"'
EOF

else
  echo "Unknown deploy path: $DEPLOY_PATH"
  exit 1
fi

