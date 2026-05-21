#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVERLESS_CONFIG="$ROOT_DIR/environment/serverless.permissions.yml"

usage() {
  cat <<EOF
Usage: ./scripts/deploy_permissions.sh <stage> [aws-profile] [region]

Examples:
  ./scripts/deploy_permissions.sh prod
  ./scripts/deploy_permissions.sh prod default us-east-1
EOF
}

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

STAGE="$1"
AWS_PROFILE="${2:-}"
AWS_REGION="${3:-us-east-1}"

if ! command -v serverless >/dev/null 2>&1; then
  echo "[INFO] serverless not found globally, using npx"
  SLS_CMD=(npx --yes serverless@3)
else
  SLS_CMD=(serverless)
fi

DEPLOY_ARGS=(
  deploy
  --config "$SERVERLESS_CONFIG"
  --stage "$STAGE"
  --region "$AWS_REGION"
)

if [ -n "$AWS_PROFILE" ]; then
  DEPLOY_ARGS+=(--aws-profile "$AWS_PROFILE")
fi

"${SLS_CMD[@]}" "${DEPLOY_ARGS[@]}"

