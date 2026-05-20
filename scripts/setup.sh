#!/bin/bash

###############################################################################
# dbt Setup Script
#
# Initializes local development environment for bit-dbt
###############################################################################

set -e

# Colors
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

log_info "Setting up bit-dbt development environment..."

# Check Python version
log_info "Checking Python version..."
python_version=$(python --version 2>&1 | awk '{print $2}')
log_info "Found Python $python_version"

# Create virtual environment if it doesn't exist
if [ ! -d "$PROJECT_ROOT/.venv" ]; then
    log_info "Creating virtual environment..."
    python -m venv "$PROJECT_ROOT/.venv"
else
    log_info "Virtual environment already exists"
fi

# Activate virtual environment
log_info "Activating virtual environment..."
source "$PROJECT_ROOT/.venv/bin/activate"

# Upgrade pip
log_info "Upgrading pip..."
pip install --upgrade pip --quiet

# Install requirements
log_info "Installing Python dependencies..."
pip install -r "$PROJECT_ROOT/requirements.txt" --quiet

# Create .env if it doesn't exist
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    log_warn ".env file not found. Copying from .env.example..."
    cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
    log_warn "Please edit .env file with your configuration"
else
    log_info ".env file already exists"
fi

# Create necessary directories
log_info "Creating project directories..."
mkdir -p "$PROJECT_ROOT/target"
mkdir -p "$PROJECT_ROOT/dbt_packages"
mkdir -p "$PROJECT_ROOT/logs"

log_info "Setup complete! ✓"

cat << EOF

${GREEN}Next Steps:${NC}
1. Edit .env file with your AWS credentials and configuration
2. Ensure you have access to AWS resources (S3, Athena, Glue)
3. Run: ${YELLOW}dbt debug${NC} to verify connection
4. Run: ${YELLOW}dbt run${NC} to execute models

${GREEN}Quick Commands:${NC}
- Activate venv: ${YELLOW}source .venv/bin/activate${NC}
- Test connection: ${YELLOW}dbt debug${NC}
- Run models: ${YELLOW}dbt run${NC}
- Run tests: ${YELLOW}dbt test${NC}
- View docs: ${YELLOW}dbt docs generate && dbt docs serve${NC}

EOF

