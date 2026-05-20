# ✅ bit-dbt Setup Checklist

Use this checklist to track setup progress for the bit-dbt service.

## 📦 Local Development Setup

- [ ] Repository cloned/created locally
- [ ] Virtual environment created (`.venv/`)
- [ ] Dependencies installed (`pip install -r requirements.txt`)
- [ ] `.env` file created from `.env.example`
- [ ] `.env` file configured with AWS credentials
- [ ] `make debug` runs successfully
- [ ] Sample model compiles (`make compile`)
- [ ] Sample model runs successfully (`make run`)
- [ ] Tests pass (`make run-test`)
- [ ] Documentation generates (`make docs`)

## 🐙 GitHub Repository Setup

- [ ] Repository created: `bandsintown/bit-dbt`
- [ ] Repository set to private
- [ ] Initial code pushed to `main` branch
- [ ] Branch protection rules configured on `main`
  - [ ] Require 2 approving reviews
  - [ ] Require status checks to pass
  - [ ] Require conversation resolution
- [ ] Team access configured
  - [ ] Data Platform Team: Admin
  - [ ] Analytics Team: Write
  - [ ] Engineering: Read
- [ ] CODEOWNERS file active and enforced
- [ ] Repository topics added (dbt, analytics, athena, etc.)
- [ ] Repository description set

## 🔐 GitHub Secrets Configuration

- [ ] `AWS_ACCESS_KEY_ID` added
- [ ] `AWS_SECRET_ACCESS_KEY` added
- [ ] `AWS_ACCESS_KEY_ID_PROD` added (for production)
- [ ] `AWS_SECRET_ACCESS_KEY_PROD` added (for production)
- [ ] `AWS_REGION` added
- [ ] `DBT_ATHENA_S3_STAGING_DIR_STAGING` added
- [ ] `DBT_ATHENA_S3_STAGING_DIR_PROD` added
- [ ] `DBT_ATHENA_WORKGROUP_STAGING` added
- [ ] `DBT_ATHENA_WORKGROUP_PROD` added
- [ ] `SLACK_WEBHOOK_URL` added

## 🔄 GitHub Actions / CI/CD

- [ ] CI workflow file present (`.github/workflows/ci.yml`)
- [ ] Deploy workflow file present (`.github/workflows/deploy.yml`)
- [ ] Test PR created to verify CI pipeline
- [ ] CI pipeline runs successfully on PR
- [ ] Linting checks pass
- [ ] Security scans pass
- [ ] Deploy workflow tested (staging)

## ☁️ AWS Infrastructure - S3

- [ ] S3 bucket created: `bandsintown-dbt-analytics`
- [ ] Folder structure created in bucket:
  - [ ] `dev/`
  - [ ] `staging/`
  - [ ] `prod/`
  - [ ] `docs/`
- [ ] Bucket versioning enabled
- [ ] Lifecycle policies configured
- [ ] S3 bucket created: `bandsintown-dbt-dev`
- [ ] S3 bucket created: `bandsintown-dbt-staging`
- [ ] S3 bucket created: `bandsintown-dbt-prod`
- [ ] S3 bucket created: `bandsintown-dbt-backups`
- [ ] S3 access tested from local environment

## ☁️ AWS Infrastructure - Athena

- [ ] Athena workgroup created: `bandsintown-dbt-dev`
- [ ] Athena workgroup created: `bandsintown-dbt-staging`
- [ ] Athena workgroup created: `bandsintown-dbt-prod`
- [ ] EMR Serverless enabled on workgroups
- [ ] Query result locations configured
- [ ] Workgroup settings validated

## ☁️ AWS Infrastructure - Glue

- [ ] Glue database created: `bandsintown_raw`
- [ ] Glue database created: `bandsintown_analytics_dev`
- [ ] Glue database created: `bandsintown_analytics_staging`
- [ ] Glue database created: `bandsintown_analytics_prod`
- [ ] Sample source table created: `bandsintown_raw.events`
- [ ] Table schema matches source definition

## ☁️ AWS Infrastructure - IAM

- [ ] IAM role created: `EMRServerlessExecutionRole`
- [ ] IAM policy created from template (`iam-policy-template.json`)
- [ ] Policy attached to EMR execution role
- [ ] Athena permissions verified
- [ ] S3 permissions verified (read raw, read/write analytics)
- [ ] Glue catalog permissions verified
- [ ] CloudWatch logging permissions verified
- [ ] Trust relationship configured for EMR Serverless

## ☁️ AWS Infrastructure - EMR Serverless

- [ ] EMR Serverless application created
- [ ] Application ID documented in `.env`
- [ ] Execution role attached to application
- [ ] Application state: STARTED
- [ ] Network configuration verified (if applicable)
- [ ] Pre-initialized capacity configured (optional)

## 🌬️ Airflow Integration

- [ ] Airflow environment accessible
- [ ] Airflow S3 bucket identified for DAG deployment
- [ ] DAG uploaded to Airflow: `bandsintown_dbt_dag.py`
- [ ] DAG appears in Airflow UI
- [ ] DAG configuration reviewed
- [ ] Environment variables configured in Airflow:
  - [ ] `DBT_PROJECT_DIR`
  - [ ] `DBT_PROFILES_DIR`
  - [ ] `DBT_TARGET`
  - [ ] `AWS_REGION`
  - [ ] All dbt Athena variables
- [ ] Airflow connections configured (if needed)
- [ ] External task sensor dependency verified (EMR ingestion DAG)

## ✅ End-to-End Validation

### Development Environment
- [ ] `dbt debug` returns "Connection test: OK"
- [ ] `dbt deps` installs packages successfully
- [ ] `dbt compile` compiles all models without errors
- [ ] `dbt run` executes stg_events model
- [ ] `stg_events` view exists in Athena
- [ ] `dbt test` passes all tests
- [ ] `dbt docs generate` creates artifacts
- [ ] Documentation artifacts uploaded to S3

### Staging Environment
- [ ] GitHub Actions deploy workflow runs successfully
- [ ] dbt project synced to S3 staging bucket
- [ ] Airflow DAG synced to staging Airflow
- [ ] Models run successfully in staging
- [ ] Tests pass in staging
- [ ] Documentation generated for staging

### Production Environment
- [ ] Production deployment requires manual approval ✓
- [ ] Backup created before deployment
- [ ] dbt project synced to S3 prod bucket
- [ ] Airflow DAG synced to prod Airflow
- [ ] Models run successfully in prod
- [ ] Tests pass in prod
- [ ] Documentation generated for prod

### Airflow DAG Execution
- [ ] DAG manually triggered
- [ ] EMR sensor completes (or skipped for testing)
- [ ] dbt_deps task succeeds
- [ ] dbt_debug task succeeds
- [ ] dbt_source_freshness task runs
- [ ] dbt_run task succeeds
- [ ] dbt_test task succeeds
- [ ] dbt_docs_generate task succeeds
- [ ] Documentation uploaded to S3
- [ ] Email notifications received (if configured)

## 🗄️ Data Validation

- [ ] Source table accessible: `bandsintown_raw.events`
- [ ] Source table has data
- [ ] Source freshness check passes
- [ ] Staging model created: `bandsintown_analytics_{env}.stg_events`
- [ ] Staging model contains expected columns
- [ ] Staging model row count matches expectations
- [ ] All column-level tests pass
- [ ] Data quality checks pass

## 📊 Monitoring & Alerts

- [ ] Slack channel configured: #data-platform-alerts
- [ ] Slack webhook tested
- [ ] Deployment notifications working
- [ ] Failure notifications working
- [ ] CloudWatch logs accessible
- [ ] CloudWatch alerts configured (optional)
- [ ] Athena query metrics monitored
- [ ] Cost monitoring enabled

## 📚 Documentation & Handoff

- [ ] README.md reviewed and complete
- [ ] QUICKSTART.md tested by new developer
- [ ] CONTRIBUTING.md guidelines established
- [ ] PROJECT_SUMMARY.md completed
- [ ] GITHUB_SETUP.md checklist completed
- [ ] Team training session scheduled
- [ ] Runbook created for common issues
- [ ] On-call procedures documented
- [ ] Knowledge transfer to analytics team
- [ ] Project demo scheduled

## 🎯 Acceptance Criteria (from Story)

- [x] bandsintown/bit-dbt repo structure complete ✅
- [ ] dbt debug returns Connection test: OK ⏳ (requires AWS setup)
- [ ] stg_events view exists in analytics Athena schema ⏳ (requires first run)
- [ ] Airflow DAG runs end-to-end without errors ⏳ (requires deployment)
- [x] dbt docs generate produces manifest.json and catalog.json ✅

## 🚀 Go-Live Checklist

**Pre-Go-Live**
- [ ] All infrastructure provisioned
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Team trained
- [ ] Runbook ready
- [ ] Monitoring configured
- [ ] Backups tested
- [ ] Rollback plan documented

**Go-Live**
- [ ] Production deployment executed
- [ ] Smoke tests passed
- [ ] Airflow DAG runs successfully
- [ ] Data validated in production
- [ ] Documentation published
- [ ] Team notified
- [ ] Status page updated

**Post-Go-Live**
- [ ] Monitor for 24 hours
- [ ] Review logs for errors
- [ ] Validate daily runs
- [ ] Collect team feedback
- [ ] Document lessons learned
- [ ] Plan next iteration

## 📝 Notes

**Date Started**: May 14, 2026  
**Project**: DI-11 (dbt Data Platform)  
**Epic**: DI-12 (Infrastructure Setup)  
**Team**: Data Platform / Complicated Subsystem Team

**Key Contacts**:
- Data Platform Lead: TBD
- DevOps Lead: TBD
- Analytics Lead: TBD

**Important Links**:
- GitHub Repo: https://github.com/bandsintown/bit-dbt
- Airflow (Staging): https://airflow.staging.bandsintown.com
- Airflow (Prod): https://airflow.bandsintown.com
- Athena Console: https://console.aws.amazon.com/athena
- Documentation (Prod): https://bandsintown-dbt-analytics.s3.amazonaws.com/docs/index.html

---

**Legend**:
- [ ] Not started
- [x] Complete
- ⏳ In progress
- ❌ Blocked

