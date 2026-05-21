#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVERLESS_CONFIG="$ROOT_DIR/environment/serverless.permissions.yml"

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

# Run from project root so relative paths in serverless config resolve consistently in CI.
cd "$ROOT_DIR"

# Prefer a preinstalled Serverless binary (common in CI). Fall back to npx package execution.
if command -v sls >/dev/null 2>&1; then
  SLS_CMD=(sls)
elif command -v serverless >/dev/null 2>&1; then
  SLS_CMD=(serverless)
elif command -v npx >/dev/null 2>&1; then
  # npm v6/v7 compatible form; do not append an extra "serverless" token.
  SLS_CMD=(npx -y serverless@3)
else
  echo "[ERROR] Neither serverless/sls nor npx is available." >&2
  exit 1
fi

DEPLOY_ARGS=(
  deploy
  --config "$SERVERLESS_CONFIG"
  --stage "$STAGE"
  --region "$AWS_REGION"
)

DEPLOY_ARGS+=(--aws-profile "$AWS_PROFILE")

"${SLS_CMD[@]}" "${DEPLOY_ARGS[@]}"

