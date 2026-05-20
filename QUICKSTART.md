# 🚀 Quick Start Guide - bit-dbt

Get up and running with bit-dbt in 5 minutes!

## Prerequisites Check

```bash
# Check Python version (need 3.9+)
python --version

# Check AWS CLI
aws --version

# Check git
git --version
```

## Step 1: Initial Setup (2 minutes)

```bash
# Navigate to project
cd /Users/vidagharavian/PycharmProjects/bit-dbt

# Run automated setup
./scripts/setup.sh

# This will:
# ✓ Create virtual environment
# ✓ Install all dependencies
# ✓ Create .env file
# ✓ Set up directories
```

## Step 2: Configure AWS (2 minutes)

```bash
# Edit environment file
nano .env

# Required variables (minimum):
AWS_REGION=us-east-1
DBT_ATHENA_S3_STAGING_DIR=s3://bandsintown-dbt-analytics/dev/
DBT_ATHENA_DATABASE=bandsintown_analytics_dev
DBT_ATHENA_WORKGROUP=bandsintown-dbt-dev
RAW_DATA_DATABASE=bandsintown_raw
```

**Option A: Use AWS Profile**
```bash
export AWS_PROFILE=your-profile-name
```

**Option B: Use AWS Credentials**
```bash
export AWS_ACCESS_KEY_ID=your-key
export AWS_SECRET_ACCESS_KEY=your-secret
```

## Step 3: Test Connection (1 minute)

```bash
# Activate virtual environment
source .venv/bin/activate

# Test dbt connection to Athena
make debug

# Expected output:
# Connection test: [OK connection ok]
```

If connection fails:
- Verify AWS credentials: `aws sts get-caller-identity`
- Check S3 access: `aws s3 ls s3://bandsintown-dbt-analytics/`
- Verify Athena workgroup: `aws athena get-work-group --work-group bandsintown-dbt-dev`

## Step 4: Run Your First Model (30 seconds)

```bash
# Run staging model
make run-model MODEL=stg_events

# Expected output:
# Completed successfully
# Done. PASS=1 WARN=0 ERROR=0 SKIP=0 TOTAL=1
```

## Step 5: Run Tests (30 seconds)

```bash
# Run dbt tests
make run-test

# Expected output:
# Tests passing confirmation
```

## 🎉 Success!

You now have:
- ✅ dbt project configured
- ✅ Connected to AWS Athena
- ✅ Staging model created: `stg_events`
- ✅ Tests passing

## Common Commands Cheat Sheet

```bash
# Development
make debug          # Test connection
make compile        # Compile models
make run            # Run all models
make run-test       # Run all tests
make docs           # Generate & view docs

# Specific operations
make run-model MODEL=stg_events    # Run specific model
make run-tag TAG=staging           # Run models by tag
make freshness                     # Check source freshness
make lint                          # Lint SQL files

# Deployment
make deploy-dev         # Deploy to dev
make deploy-staging     # Deploy to staging
make deploy-prod        # Deploy to production
```

## View Your Data

### In Athena Console
```sql
-- Check your view was created
SHOW TABLES IN bandsintown_analytics_dev;

-- Query the staging model
SELECT * FROM bandsintown_analytics_dev.stg_events LIMIT 10;
```

### Using AWS CLI
```bash
# Start query
aws athena start-query-execution \
  --query-string "SELECT COUNT(*) FROM bandsintown_analytics_dev.stg_events" \
  --query-execution-context Database=bandsintown_analytics_dev \
  --result-configuration OutputLocation=s3://bandsintown-dbt-analytics/dev/
```

## View Documentation

```bash
# Generate and serve docs
make docs

# Opens browser at: http://localhost:8080
# Shows:
# - Data lineage diagram
# - Model documentation
# - Column descriptions
# - Test results
```

## Troubleshooting

### "Connection failed"
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check environment variables
env | grep DBT
env | grep AWS
```

### "S3 access denied"
```bash
# Verify S3 bucket access
aws s3 ls s3://bandsintown-dbt-analytics/

# Check IAM permissions
aws iam get-user
```

### "Athena workgroup not found"
```bash
# List available workgroups
aws athena list-work-groups

# Get workgroup details
aws athena get-work-group --work-group bandsintown-dbt-dev
```

### "Model compilation failed"
```bash
# Clean and retry
make clean
make deps
make compile
```

## Next Steps

### Add More Models
1. Create new SQL file in `models/staging/`
2. Add schema definition in `.yml` file
3. Run: `make run-model MODEL=your_model_name`
4. Add tests in schema file
5. Run: `make run-test`

### Customize Configuration
- Edit `dbt_project.yml` for project settings
- Edit `profiles.yml` for connection settings
- Add macros in `macros/` directory
- Add custom tests in `tests/` directory

### Set Up CI/CD
1. Push code to GitHub
2. Configure repository secrets (see GITHUB_SETUP.md)
3. CI runs automatically on PRs
4. Deploy workflow runs on merge to main

### Deploy to Production
```bash
# Deploy to staging first
make deploy-staging

# After validation, deploy to prod
make deploy-prod
```

## Getting Help

**Documentation**
- Full README: `README.md`
- Contributing guide: `CONTRIBUTING.md`
- GitHub setup: `GITHUB_SETUP.md`
- Project summary: `PROJECT_SUMMARY.md`

**Support**
- Slack: #data-platform
- Email: data-platform@bandsintown.com

**Resources**
- dbt Docs: https://docs.getdbt.com/
- dbt-athena: https://github.com/dbt-athena/dbt-athena
- AWS Athena: https://docs.aws.amazon.com/athena/

---

**Time to first model: ~5 minutes** ⚡

Happy transforming! 🎸

