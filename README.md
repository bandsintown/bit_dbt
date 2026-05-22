# bit-dbt - Bandsintown dbt Data Transformation Service

This repository contains the dbt (data build tool) project for Bandsintown's data analytics platform, integrated with AWS EMR Serverless and orchestrated via Apache Airflow.

## 🎯 Overview

**Project**: dbt Data Platform (DI-11)  
**Epic**: Infrastructure Setup (DI-12)  
**Owner**: Complicated Subsystem Team / Data Platform Team

This service transforms raw data from EMR ingestion pipelines into analytics-ready datasets using dbt Core, with models materialized in AWS Athena.

## 🏗️ Architecture

```
EMR Ingestion → S3 Raw Data → Athena (bandsintown_raw)
                                    ↓
                              dbt Transformations
                              (EMR Serverless)
                                    ↓
                         Athena Analytics Schema
                    (staging → intermediate → marts)
```

## 📋 Prerequisites

- Python 3.9+
- AWS Account with appropriate IAM permissions
- Access to Bandsintown AWS resources:
  - S3: `s3://bandsintown-dbt-analytics/`
  - Athena Workgroup: `bandsintown-dbt-{env}`
  - EMR Serverless Application
- Airflow environment (for production deployments)

## 🚀 Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone git@github.com:bandsintown/bit-dbt.git
cd bit-dbt

# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your configuration
# Set AWS credentials, region, S3 paths, Athena workgroup, etc.
```

Required environment variables:
- `AWS_REGION` - AWS region (e.g., us-east-1)
- `DBT_ATHENA_S3_STAGING_DIR` - S3 path for Athena query results
- `DBT_ATHENA_S3_DATA_DIR` - S3 path for dbt table data
- `DBT_ATHENA_DATABASE` - Athena database name
- `DBT_ATHENA_WORKGROUP` - Athena workgroup name (EMR Serverless enabled)
- `DBT_TARGET` - Target environment (dev/staging/prod)

### 3. Verify Connection

```bash
# Set profiles directory
export DBT_PROFILES_DIR=$(pwd)

# Test connection to Athena
dbt debug

# Expected output: "Connection test: OK"
```

### 4. Run dbt Models

```bash
# Install dbt packages (if any)
dbt deps

# Run all models
dbt run

# Run specific models
dbt run --select stg_events

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve  # View docs at http://localhost:8080
```

## 📁 Project Structure

```
bit-dbt/
├── models/
│   ├── staging/              # Staging models (views)
│   │   └── bandsintown_raw/
│   │       ├── src_bandsintown_raw.yml
│   │       ├── stg_events.sql
│   │       └── stg_bandsintown_raw.yml
│   ├── intermediate/         # Intermediate business logic (views)
│   └── marts/                # Final analytics tables
├── macros/                   # Custom dbt macros
├── tests/                    # Custom data tests
├── seeds/                    # CSV reference data
├── snapshots/                # SCD Type 2 snapshots
├── analyses/                 # Ad-hoc SQL queries
├── airflow/
│   └── dags/
│       └── bandsintown_dbt_dag.py
├── dbt_project.yml           # dbt project configuration
├── profiles.yml              # dbt connection profiles
├── requirements.txt          # Python dependencies
├── .env.example              # Environment variable template
├── .gitignore
└── README.md
```

## 🔧 dbt Configuration

### Materialization Strategy

- **Staging** (`models/staging/`): Views - Fast, lightweight transformations
- **Intermediate** (`models/intermediate/`): Views - Business logic, reusable
- **Marts** (`models/marts/`): Tables - Final consumption layer

### Schema Layout

```
bandsintown_raw         → Source data (read-only)
  └── events
  
bandsintown_analytics_{env}
  ├── staging           → stg_events, stg_artists, etc.
  ├── intermediate      → int_* models
  └── analytics         → dim_*, fct_* final tables
```

## 🔐 IAM Permissions

The EMR Serverless execution role requires:

**Athena Permissions:**
- `athena:StartQueryExecution`
- `athena:GetQueryExecution`
- `athena:GetQueryResults`
- `athena:StopQueryExecution`

**S3 Permissions:**
- Read: `s3://bandsintown-raw-data/*`
- Read/Write: `s3://bandsintown-dbt-analytics/*`

**Glue Permissions:**
- `glue:GetDatabase`
- `glue:GetTable`
- `glue:GetPartitions`
- `glue:CreateTable`
- `glue:UpdateTable`
- `glue:DeleteTable`

See `iam-policy-template.json` for full policy.

## 🔄 Running dbt Transformations

Run dbt transformations directly from the command line:

**Basic Workflow:**
```bash
# Install dependencies
dbt deps

# Test connection
dbt debug

# Check source data freshness
dbt source freshness

# Run transformations
dbt run

# Run data quality tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

**Schedule with Cron (Optional):**
```bash
# Add to crontab for daily runs at 6 AM
0 6 * * * cd /path/to/bit-dbt && source .venv/bin/activate && dbt run && dbt test
```

## 🧪 Testing

### Run All Tests
```bash
dbt test
```

### Source Freshness
```bash
dbt source freshness
```

### Test Specific Model
```bash
dbt test --select stg_events
```

## 📊 Data Quality

dbt tests ensure:
- Primary keys are unique and not null
- Foreign key relationships are valid
- Accepted values match expected enums
- Source data freshness (< 24 hours)
- Custom business logic validations

## 🚢 Deployment

### Development
```bash
export DBT_TARGET=dev
dbt run
```

### Staging
```bash
export DBT_TARGET=staging
dbt run --full-refresh
```

### Production
Deployed via Airflow DAG automatically after EMR ingestion completes.

### IAM Permissions (Serverless)

Deploy the IAM permissions stack with:

```bash
make deploy-permissions STAGE=prod AWS_PROFILE=default AWS_REGION=us-east-1
```

There is also a GitHub Actions pipeline at `.github/workflows/deploy-serverless-permissions.yml`.
It deploys automatically on changes to the IAM Serverless config and can be run manually via workflow dispatch.

### Airflow dbt Runtime Payload

Buildkite `upload_s3` now uploads:
- `scripts/` to `s3://bit-dbt-<env>/dags/dependencies/dbt/scripts/`
- dbt project payload to `s3://bit-dbt-<env>/dags/dependencies/dbt/project/`

In Airflow/MWAA, use:

```bash
/usr/local/airflow/dags/dependencies/dbt/scripts/run_dbt.sh run
/usr/local/airflow/dags/dependencies/dbt/scripts/run_dbt.sh test
```

The helper script accepts additional dbt args, for example:

```bash
/usr/local/airflow/dags/dependencies/dbt/scripts/run_dbt.sh build --select tag:daily
```

## 📖 Documentation

Generate and view dbt documentation:

```bash
dbt docs generate
dbt docs serve
```

Documentation artifacts are automatically uploaded to S3 after each production run:
- `s3://bandsintown-dbt-analytics/docs/manifest.json`
- `s3://bandsintown-dbt-analytics/docs/catalog.json`

## 🐛 Troubleshooting

### Connection Issues

```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify S3 access
aws s3 ls s3://bandsintown-dbt-analytics/

# Test Athena workgroup
aws athena get-work-group --work-group bandsintown-dbt-prod
```

### dbt Errors

```bash
# Clear cache and retry
dbt clean
dbt deps
dbt run

# Verbose logging
dbt run --debug

# Run single model with full refresh
dbt run --select stg_events --full-refresh
```

## 🤝 Contributing

1. Create a feature branch from `main`
2. Make changes and test locally
3. Submit PR with description and tests
4. Require 2 approvals from data platform team
5. Merge to `main` triggers deployment to staging
6. Manual promotion to production

## 📞 Support

**Team**: Data Platform / Complicated Subsystem Team  
**Slack**: #data-platform  
**Email**: data-platform@bandsintown.com

## 📚 Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [dbt-athena-community](https://github.com/dbt-athena/dbt-athena)
- [Bandsintown Engineering Handbook](https://handbook.bandsintown.com/)
- [EMR Serverless Documentation](https://docs.aws.amazon.com/emr/latest/EMR-Serverless-UserGuide/)

## 📝 License

Proprietary - Bandsintown, Inc.

---

**Last Updated**: May 14, 2026  
**Version**: 1.0.0

