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

if ! command -v npx >/dev/null 2>&1; then
  echo "[ERROR] npx is required (install Node.js/npm)." >&2
  exit 1
fi

# Run from project root so relative paths in serverless config resolve consistently in CI.
cd "$ROOT_DIR"
SLS_CMD=(npx --yes serverless@3)

DEPLOY_ARGS=(
  deploy
  --config "$SERVERLESS_CONFIG"
  --stage "$STAGE"
  --region "$AWS_REGION"
)

DEPLOY_ARGS+=(--aws-profile "$AWS_PROFILE")

"${SLS_CMD[@]}" "${DEPLOY_ARGS[@]}"

