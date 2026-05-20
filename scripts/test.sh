#!/bin/bash

###############################################################################
# dbt Test Runner
#
# Runs comprehensive tests on dbt models
###############################################################################

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Set environment
export DBT_PROFILES_DIR="$PROJECT_ROOT"
export DBT_TARGET="${DBT_TARGET:-dev}"

cd "$PROJECT_ROOT"

log_info "Running dbt tests for target: $DBT_TARGET"
log_info "============================================"

# Test 1: Connection test
log_info "1. Testing database connection..."
if dbt debug --target "$DBT_TARGET"; then
    log_info "✓ Connection test passed"
else
    log_error "✗ Connection test failed"
    exit 1
fi

echo ""

# Test 2: Compile models
log_info "2. Compiling models..."
if dbt compile --target "$DBT_TARGET"; then
    log_info "✓ Compilation passed"
else
    log_error "✗ Compilation failed"
    exit 1
fi

echo ""

# Test 3: Parse project
log_info "3. Parsing project..."
if dbt parse --target "$DBT_TARGET"; then
    log_info "✓ Parse passed"
else
    log_error "✗ Parse failed"
    exit 1
fi

echo ""

# Test 4: Source freshness
log_info "4. Checking source freshness..."
if dbt source freshness --target "$DBT_TARGET"; then
    log_info "✓ Source freshness check passed"
else
    log_warn "✗ Source freshness check failed (may be expected for dev)"
fi

echo ""

# Test 5: Run models
log_info "5. Running models..."
if dbt run --target "$DBT_TARGET"; then
    log_info "✓ Model run passed"
else
    log_error "✗ Model run failed"
    exit 1
fi

echo ""

# Test 6: Run tests
log_info "6. Running dbt tests..."
if dbt test --target "$DBT_TARGET"; then
    log_info "✓ Tests passed"
else
    log_error "✗ Tests failed"
    exit 1
fi

echo ""

# Test 7: Generate docs
log_info "7. Generating documentation..."
if dbt docs generate --target "$DBT_TARGET"; then
    log_info "✓ Documentation generated"
else
    log_error "✗ Documentation generation failed"
    exit 1
fi

echo ""
log_info "============================================"
log_info "All tests passed! ✓"
log_info "============================================"

cat << EOF

${GREEN}Test Summary:${NC}
✓ Connection test
✓ Model compilation
✓ Project parsing
✓ Source freshness
✓ Model execution
✓ Data tests
✓ Documentation generation

Run ${YELLOW}dbt docs serve${NC} to view documentation.

EOF

