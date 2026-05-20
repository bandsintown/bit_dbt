#!/bin/bash

###############################################################################
# Git Repository Initialization Script
#
# Initializes git repository and creates initial commit for bit-dbt
###############################################################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

log_info "Initializing git repository for bit-dbt..."

# Check if git is already initialized
if [ -d ".git" ]; then
    log_warn "Git repository already initialized"
    exit 0
fi

# Initialize git
log_info "Running git init..."
git init

# Set main as default branch
git branch -M main

# Add all files
log_info "Adding files to git..."
git add .

# Create initial commit
log_info "Creating initial commit..."
git commit -m "feat: initial bit-dbt project setup

- Configure dbt Core project with staging/intermediate/marts structure
- Add dbt-athena-community adapter for EMR Serverless integration
- Create sample staging model (stg_events) with tests
- Add Airflow DAG for orchestration (bandsintown_dbt)
- Configure CI/CD with GitHub Actions (compile, test, lint, security)
- Add deployment automation scripts
- Create comprehensive documentation (README, QUICKSTART, CONTRIBUTING)
- Add Makefile for common commands
- Configure SQL linting with sqlfluff
- Add IAM policy template for AWS permissions

Project: DI-11 (dbt Data Platform)
Epic: DI-12 (Infrastructure Setup)
Team: Data Platform / Complicated Subsystem Team

Files created: 28+
Ready for: GitHub push, AWS setup, Airflow deployment"

log_info "✓ Git repository initialized successfully!"

cat << EOF

${GREEN}Next Steps:${NC}

1. Add remote repository:
   ${YELLOW}git remote add origin git@github.com:bandsintown/bit-dbt.git${NC}

2. Push to GitHub:
   ${YELLOW}git push -u origin main${NC}

3. Configure GitHub repository (see GITHUB_SETUP.md):
   - Branch protection
   - Team access
   - Secrets
   - CI/CD

EOF

