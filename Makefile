.PHONY: help setup install clean test run docs deploy deploy-permissions

# Default target
help:
	@echo "bit-dbt Makefile Commands"
	@echo "========================="
	@echo "make setup          - Set up development environment"
	@echo "make install        - Install Python dependencies"
	@echo "make clean          - Clean build artifacts"
	@echo "make test           - Run all dbt tests"
	@echo "make run            - Run dbt models"
	@echo "make docs           - Generate and serve documentation"
	@echo "make deploy-dev     - Deploy to development"
	@echo "make deploy-staging - Deploy to staging"
	@echo "make deploy-prod    - Deploy to production"
	@echo "make deploy-permissions STAGE=prod [AWS_PROFILE=default] [AWS_REGION=us-east-1] - Deploy IAM permissions stack"
	@echo "make debug          - Run dbt debug"
	@echo "make compile        - Compile dbt models"
	@echo "make lint           - Lint SQL files"

# Setup development environment
setup:
	@./scripts/setup.sh

# Install dependencies
install:
	pip install --upgrade pip
	pip install -r requirements.txt

# Clean build artifacts
clean:
	rm -rf target/
	rm -rf dbt_packages/
	rm -rf logs/
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete

# Run all tests
test:
	@./scripts/test.sh

# Run dbt models
run:
	dbt run --profiles-dir . --target $(or $(DBT_TARGET),dev)

# Run specific model
run-model:
	@test -n "$(MODEL)" || (echo "Error: MODEL is required. Usage: make run-model MODEL=stg_events" && exit 1)
	dbt run --profiles-dir . --target $(or $(DBT_TARGET),dev) --select $(MODEL)

# Run dbt tests
run-test:
	dbt test --profiles-dir . --target $(or $(DBT_TARGET),dev)

# Generate and serve documentation
docs:
	dbt docs generate --profiles-dir . --target $(or $(DBT_TARGET),dev)
	dbt docs serve --profiles-dir . --port 8080

# Generate docs only (no serve)
docs-generate:
	dbt docs generate --profiles-dir . --target $(or $(DBT_TARGET),dev)

# Run dbt debug
debug:
	dbt debug --profiles-dir . --target $(or $(DBT_TARGET),dev)

# Compile models
compile:
	dbt compile --profiles-dir . --target $(or $(DBT_TARGET),dev)

# Parse project
parse:
	dbt parse --profiles-dir . --target $(or $(DBT_TARGET),dev)

# Check source freshness
freshness:
	dbt source freshness --profiles-dir . --target $(or $(DBT_TARGET),dev)

# Install dbt packages
deps:
	dbt deps --profiles-dir . --target $(or $(DBT_TARGET),dev)

# Lint SQL files
lint:
	sqlfluff lint models/ --dialect athena

# Fix SQL files
lint-fix:
	sqlfluff fix models/ --dialect athena

# Deploy to development
deploy-dev:
	DBT_TARGET=dev ./scripts/deploy.sh dev

# Deploy to staging
deploy-staging:
	DBT_TARGET=staging ./scripts/deploy.sh staging

# Deploy to production
deploy-prod:
	DBT_TARGET=prod ./scripts/deploy.sh prod

# Deploy IAM permissions using Serverless
deploy-permissions:
	@test -n "$(STAGE)" || (echo "Error: STAGE is required. Usage: make deploy-permissions STAGE=prod [AWS_PROFILE=default] [AWS_REGION=us-east-1]" && exit 1)
	./scripts/deploy_permissions.sh $(STAGE) $(AWS_PROFILE) $(or $(AWS_REGION),us-east-1)

# Full refresh all models
refresh:
	dbt run --profiles-dir . --target $(or $(DBT_TARGET),dev) --full-refresh

# Run specific tag
run-tag:
	@test -n "$(TAG)" || (echo "Error: TAG is required. Usage: make run-tag TAG=staging" && exit 1)
	dbt run --profiles-dir . --target $(or $(DBT_TARGET),dev) --select tag:$(TAG)

# List all models
list-models:
	dbt list --profiles-dir . --target $(or $(DBT_TARGET),dev) --resource-type model

# List all sources
list-sources:
	dbt list --profiles-dir . --target $(or $(DBT_TARGET),dev) --resource-type source

# Show DAG
show-dag:
	@test -n "$(MODEL)" || (echo "Error: MODEL is required. Usage: make show-dag MODEL=stg_events" && exit 1)
	dbt run-operation generate_model_yaml --args '{model_name: $(MODEL)}'

