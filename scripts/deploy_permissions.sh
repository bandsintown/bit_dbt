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

# Bootstrap deployment bucket if it does not exist yet.
DEPLOYMENT_BUCKET="bit-dbt-${STAGE}"
echo "Checking deployment bucket: $DEPLOYMENT_BUCKET"
if aws s3api head-bucket --bucket "$DEPLOYMENT_BUCKET" --profile "$AWS_PROFILE" 2>/dev/null; then
  echo "Deployment bucket already exists."
else
  echo "Creating deployment bucket: $DEPLOYMENT_BUCKET"
  aws s3 mb "s3://$DEPLOYMENT_BUCKET" --region "$AWS_REGION" --profile "$AWS_PROFILE"
  aws s3api put-public-access-block \
    --bucket "$DEPLOYMENT_BUCKET" \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
    --profile "$AWS_PROFILE"
  echo "Deployment bucket created."
fi

# Run inside the Serverless service directory.
cd "$SERVICE_DIR"

# Use npm-compatible npx syntax and pin a Serverless version that matches the Node runtime.
if ! command -v npx >/dev/null 2>&1; then
  echo "[ERROR] npx is required to run a pinned Serverless CLI in CI." >&2
  exit 1
fi

NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
if [ "$NODE_MAJOR" -lt 16 ]; then
  SERVERLESS_VERSION="2.72.4"
else
  SERVERLESS_VERSION="3"
fi

echo "NODE_MAJOR=$NODE_MAJOR"
echo "SERVERLESS_VERSION=$SERVERLESS_VERSION"
SLS_CMD=(npx -p "serverless@${SERVERLESS_VERSION}" sls)

DEPLOY_ARGS=(
  deploy
  --config "$SERVERLESS_CONFIG_FILE"
  --stage "$STAGE"
  --region "$AWS_REGION"
)

DEPLOY_ARGS+=(--aws-profile "$AWS_PROFILE")

"${SLS_CMD[@]}" "${DEPLOY_ARGS[@]}"

