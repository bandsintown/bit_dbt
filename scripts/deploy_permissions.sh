#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_DIR="$ROOT_DIR/environment"
SERVERLESS_CONFIG_FILE="serverless.permissions.yml"

usage() {
  cat <<EOF
Usage: ./scripts/deploy_permissions.sh <stage> [aws-profile] [region]

Examples:
  ./scripts/deploy_permissions.sh prod
  ./scripts/deploy_permissions.sh prod bit-prod us-east-1
EOF
}

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

STAGE="$1"
AWS_PROFILE="${2:-bit-$STAGE}"
AWS_REGION="${3:-us-east-1}"

echo "STAGE=$STAGE"
echo "AWS_PROFILE=$AWS_PROFILE"
echo "AWS_REGION=$AWS_REGION"

export AWS_SDK_LOAD_CONFIG=1
export SLS_DEBUG="${SLS_DEBUG:-*}"

# Run inside the Serverless service directory.
cd "$SERVICE_DIR"

# Use npm v6/v7 compatible npx syntax to pin Serverless v3 and avoid global CLI conflicts.
if ! command -v npx >/dev/null 2>&1; then
  echo "[ERROR] npx is required to run pinned Serverless v3 in CI." >&2
  exit 1
fi
SLS_CMD=(npx -p serverless@3 sls)

DEPLOY_ARGS=(
  deploy
  --config "$SERVERLESS_CONFIG_FILE"
  --stage "$STAGE"
  --region "$AWS_REGION"
)

DEPLOY_ARGS+=(--aws-profile "$AWS_PROFILE")

"${SLS_CMD[@]}" "${DEPLOY_ARGS[@]}"

