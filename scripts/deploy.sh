#!/bin/bash

###############################################################################
# dbt Deployment Script
#
# This script packages and deploys the dbt project to the specified environment
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_usage() {
    cat << EOF
Usage: ./scripts/deploy.sh [ENVIRONMENT]

Deploy dbt project to specified environment

ENVIRONMENT:
    dev         Deploy to development
    staging     Deploy to staging
    prod        Deploy to production

Examples:
    ./scripts/deploy.sh dev
    ./scripts/deploy.sh staging
    ./scripts/deploy.sh prod

EOF
}

validate_environment() {
    local env=$1
    case $env in
        dev|staging|prod)
            return 0
            ;;
        *)
            log_error "Invalid environment: $env"
            show_usage
            exit 1
            ;;
    esac
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check for required commands
    command -v dbt >/dev/null 2>&1 || { log_error "dbt is not installed"; exit 1; }
    command -v aws >/dev/null 2>&1 || { log_error "AWS CLI is not installed"; exit 1; }
    command -v python >/dev/null 2>&1 || { log_error "Python is not installed"; exit 1; }

    # Check AWS credentials
    aws sts get-caller-identity >/dev/null 2>&1 || {
        log_error "AWS credentials not configured or invalid"
        exit 1
    }

    log_info "Prerequisites check passed ✓"
}

run_tests() {
    log_info "Running dbt tests..."

    cd "$PROJECT_ROOT"

    # Run dbt debug
    dbt debug --profiles-dir "$PROJECT_ROOT" --target "$TARGET_ENV" || {
        log_error "dbt debug failed"
        exit 1
    }

    # Run dbt compile to check for syntax errors
    dbt compile --profiles-dir "$PROJECT_ROOT" --target "$TARGET_ENV" || {
        log_error "dbt compile failed"
        exit 1
    }

    log_info "Tests passed ✓"
}

deploy_to_airflow() {
    local env=$1
    log_info "Deploying Airflow DAG to $env..."

    # Determine S3 bucket based on environment
    case $env in
        dev)
            AIRFLOW_S3_BUCKET="bandsintown-airflow-dev"
            ;;
        staging)
            AIRFLOW_S3_BUCKET="bandsintown-airflow-staging"
            ;;
        prod)
            AIRFLOW_S3_BUCKET="bandsintown-airflow-prod"
            ;;
    esac

    # Upload DAG to S3
    aws s3 cp "$PROJECT_ROOT/airflow/dags/bandsintown_dbt_dag.py" \
        "s3://$AIRFLOW_S3_BUCKET/dags/bandsintown_dbt_dag.py" || {
        log_error "Failed to upload Airflow DAG to S3"
        exit 1
    }

    log_info "Airflow DAG deployed ✓"
}

deploy_dbt_project() {
    local env=$1
    log_info "Deploying dbt project to $env..."

    # Determine S3 bucket based on environment
    case $env in
        dev)
            DBT_S3_BUCKET="bandsintown-dbt-dev"
            ;;
        staging)
            DBT_S3_BUCKET="bandsintown-dbt-staging"
            ;;
        prod)
            DBT_S3_BUCKET="bandsintown-dbt-prod"
            ;;
    esac

    # Create deployment package
    log_info "Creating deployment package..."
    cd "$PROJECT_ROOT"

    # Sync dbt project to S3 (excluding unnecessary files)
    aws s3 sync . "s3://$DBT_S3_BUCKET/" \
        --exclude ".venv/*" \
        --exclude ".idea/*" \
        --exclude ".git/*" \
        --exclude "target/*" \
        --exclude "dbt_packages/*" \
        --exclude "logs/*" \
        --exclude ".env" \
        --exclude "*.pyc" \
        --exclude "__pycache__/*" || {
        log_error "Failed to sync dbt project to S3"
        exit 1
    }

    log_info "dbt project deployed ✓"
}

run_deployment() {
    local env=$1

    log_info "Starting deployment to $env environment..."

    # Set environment variables
    export DBT_TARGET=$env
    export DBT_PROFILES_DIR="$PROJECT_ROOT"
    export TARGET_ENV=$env

    # Load environment-specific variables
    if [ -f "$PROJECT_ROOT/.env.$env" ]; then
        log_info "Loading environment variables from .env.$env"
        set -a
        source "$PROJECT_ROOT/.env.$env"
        set +a
    fi

    # Run deployment steps
    check_prerequisites
    run_tests
    deploy_dbt_project "$env"
    deploy_to_airflow "$env"

    log_info "Deployment to $env completed successfully! ✓"

    # Show next steps
    cat << EOF

${GREEN}Next Steps:${NC}
1. Verify Airflow DAG appears in UI: bandsintown_dbt
2. Trigger a test run of the DAG
3. Monitor execution logs
4. Verify dbt models are created in Athena

${GREEN}Verification Commands:${NC}
- Check Athena tables: aws athena list-table-metadata --catalog-name AwsDataCatalog --database-name bandsintown_analytics_${env}
- View dbt docs: dbt docs serve --profiles-dir $PROJECT_ROOT --target $env

EOF
}

# Main execution
main() {
    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi

    TARGET_ENV=$1
    validate_environment "$TARGET_ENV"
    run_deployment "$TARGET_ENV"
}

main "$@"

