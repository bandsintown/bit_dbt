# Bandsintown dbt Project - GitHub Repository Configuration

## Repository Setup Checklist

### 1. Repository Creation
- [ ] Create repository: `bandsintown/bit-dbt`
- [ ] Set description: "dbt data transformation service for Bandsintown analytics platform"
- [ ] Set visibility: Private
- [ ] Initialize with README: No (we have our own)

### 2. Branch Protection Rules

**Branch: `main`**
- [ ] Require pull request reviews before merging
  - Required approving reviews: 2
  - Dismiss stale pull request approvals when new commits are pushed
- [ ] Require status checks to pass before merging
  - Require branches to be up to date before merging
  - Status checks: 
    - `dbt-compile`
    - `dbt-test`
    - `security-scan`
- [ ] Require conversation resolution before merging
- [ ] Do not allow bypassing the above settings (even for admins)

### 3. Team Access

**Data Platform Team**
- Role: Admin
- Members: @data-platform-team

**Analytics Team**
- Role: Write
- Members: @analytics-team

**Engineering (Read-only)**
- Role: Read
- Members: @engineering-all

### 4. Repository Settings

**General**
- [ ] Disable Wiki
- [ ] Disable Issues (use Jira)
- [ ] Disable Projects
- [ ] Enable Discussions: No
- [ ] Allow merge commits: Yes
- [ ] Allow squash merging: Yes
- [ ] Allow rebase merging: No
- [ ] Automatically delete head branches: Yes

**Security**
- [ ] Enable Dependabot alerts
- [ ] Enable Dependabot security updates
- [ ] Enable secret scanning
- [ ] Enable code scanning (CodeQL)

### 5. GitHub Actions Workflows

Create `.github/workflows/` with:

**CI Workflow** (`.github/workflows/ci.yml`)
- Triggers: Pull requests to `main`
- Jobs:
  - `dbt-compile`: Compile all models
  - `dbt-test`: Run data tests
  - `security-scan`: Check for security vulnerabilities
  - `lint`: SQL linting with sqlfluff

**Deploy Workflow** (`.github/workflows/deploy.yml`)
- Triggers: Push to `main`
- Jobs:
  - Deploy to staging environment
  - Run integration tests
  - Manual approval gate
  - Deploy to production

### 6. Repository Secrets

Add these secrets in Settings → Secrets and variables → Actions:

**AWS Credentials**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

**dbt Configuration**
- `DBT_ATHENA_S3_STAGING_DIR_STAGING`
- `DBT_ATHENA_S3_STAGING_DIR_PROD`
- `DBT_ATHENA_WORKGROUP_STAGING`
- `DBT_ATHENA_WORKGROUP_PROD`

**Notifications**
- `SLACK_WEBHOOK_URL` (for deployment notifications)

### 7. Repository Labels

Create labels for issue/PR management:
- `dbt-model` - New dbt model
- `bug` - Bug fix
- `enhancement` - New feature
- `documentation` - Documentation update
- `infrastructure` - Infrastructure change
- `breaking-change` - Breaking change
- `needs-review` - Needs review
- `staging` - Deployed to staging
- `production` - Deployed to production

### 8. Integration Configuration

**Slack Integration**
- Channel: #data-platform-alerts
- Notifications:
  - Deployment status
  - PR reviews required
  - CI/CD failures

**Jira Integration**
- Project: DI (Data Infrastructure)
- Epic: DI-12
- Link PRs to Jira tickets automatically

### 9. CODEOWNERS File

Create `.github/CODEOWNERS`:
```
# Data Platform Team owns all files by default
* @bandsintown/data-platform-team

# Airflow DAGs require additional review
/airflow/ @bandsintown/data-platform-team @bandsintown/data-engineering-leads

# Infrastructure changes require DevOps review
/iam-policy-template.json @bandsintown/devops-team
/scripts/deploy.sh @bandsintown/devops-team
```

### 10. Repository Topics

Add topics for discoverability:
- `dbt`
- `analytics`
- `data-engineering`
- `emr-serverless`
- `athena`
- `airflow`
- `bandsintown`

### 11. README Badges

Add to README.md:
- Build status
- dbt version
- Python version
- Last deployment date
- Coverage (if applicable)

---

## Post-Setup Verification

- [ ] Clone repository and verify access
- [ ] Create test PR to verify branch protection
- [ ] Verify CI/CD workflows trigger correctly
- [ ] Test deployment to staging environment
- [ ] Verify Slack notifications work
- [ ] Confirm CODEOWNERS enforcement
- [ ] Test Dependabot alerts

## GitHub CLI Commands

```bash
# Create repository (if using gh CLI)
gh repo create bandsintown/bit-dbt --private --description "dbt data transformation service"

# Set branch protection
gh api repos/bandsintown/bit-dbt/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["dbt-compile","dbt-test"]}' \
  --field required_pull_request_reviews='{"required_approving_review_count":2}' \
  --field enforce_admins=true

# Add topics
gh repo edit bandsintown/bit-dbt \
  --add-topic dbt \
  --add-topic analytics \
  --add-topic data-engineering \
  --add-topic emr-serverless \
  --add-topic athena \
  --add-topic airflow
```

## Notes

- All settings follow Bandsintown Engineering Handbook standards
- Security is enforced at repository level
- No secrets should ever be committed
- All deployments go through staging first
- Production deployments require manual approval

