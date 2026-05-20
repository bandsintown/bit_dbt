# Contributor Guide - bit-dbt

## Getting Started

### Prerequisites
- Python 3.9 or higher
- AWS CLI configured with appropriate credentials
- Access to Bandsintown AWS account
- Git

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone git@github.com:bandsintown/bit-dbt.git
   cd bit-dbt
   ```

2. **Run setup script**
   ```bash
   ./scripts/setup.sh
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your AWS credentials
   ```

4. **Verify connection**
   ```bash
   make debug
   ```

## Development Workflow

### 1. Create a Branch
```bash
git checkout -b feature/your-feature-name
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring

### 2. Make Changes

#### Adding a New Model

1. Create SQL file in appropriate directory:
   - Staging: `models/staging/<source>/`
   - Intermediate: `models/intermediate/`
   - Marts: `models/marts/<domain>/`

2. Follow naming conventions:
   - Staging: `stg_<source>_<entity>.sql`
   - Intermediate: `int_<entity>_<verb>.sql`
   - Marts: `fct_<entity>.sql` or `dim_<entity>.sql`

3. Create schema YAML file:
   ```yaml
   version: 2
   
   models:
     - name: your_model_name
       description: Clear description
       columns:
         - name: column_name
           description: Column description
           tests:
             - not_null
             - unique
   ```

4. Add appropriate tests

#### SQL Style Guide

- Use lowercase for SQL keywords
- Use 4 spaces for indentation
- Use trailing commas
- Use CTEs (Common Table Expressions) for readability
- Add comments for complex logic

Example:
```sql
{{
    config(
        materialized='view',
        tags=['staging']
    )
}}

with source as (
    
    select * from {{ source('bandsintown_raw', 'table_name') }}

),

renamed as (

    select
        id,
        name,
        created_at,
        
        -- Derived fields
        cast(created_at as date) as created_date
        
    from source
    
    where id is not null

)

select * from renamed
```

### 3. Test Locally

```bash
# Compile and check for syntax errors
make compile

# Run your specific model
make run-model MODEL=your_model_name

# Run tests
make run-test

# Run all checks
make test
```

### 4. Lint Your Code

```bash
make lint
```

Fix any linting issues:
```bash
make lint-fix
```

### 5. Commit Your Changes

```bash
git add .
git commit -m "feat: add stg_events model with tests"
```

Commit message conventions:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `test:` - Tests
- `refactor:` - Code refactoring
- `chore:` - Maintenance

### 6. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Create a Pull Request on GitHub with:
- Clear title and description
- Link to Jira ticket (e.g., "Closes DI-123")
- Screenshots or examples if applicable
- Testing instructions

### 7. Code Review

- Require 2 approvals from data platform team
- Address all review comments
- Ensure CI checks pass
- Resolve any merge conflicts

### 8. Merge

Once approved:
- Use "Squash and merge"
- Delete the branch after merging

## Common Tasks

### Running dbt Commands

```bash
# Run all models
make run

# Run specific model
make run-model MODEL=stg_events

# Run models with specific tag
make run-tag TAG=staging

# Full refresh (rebuild tables)
make refresh

# Check source freshness
make freshness

# Generate documentation
make docs
```

### Testing

```bash
# Run all tests
make test

# Test specific model
dbt test --select stg_events

# Test sources only
dbt test --select source:*
```

### Debugging

```bash
# Check connection
make debug

# Compile with detailed output
dbt compile --debug

# Run with verbose logging
dbt run --debug --select your_model
```

## Best Practices

### 1. Model Organization
- Staging: Raw → clean (1:1 with source tables)
- Intermediate: Business logic, reusable components
- Marts: Final analytics tables

### 2. Testing
- Add tests for all primary keys (unique, not_null)
- Add tests for foreign keys (relationships)
- Add tests for important business rules
- Use custom tests for complex validations

### 3. Documentation
- Document all models in schema.yml
- Add descriptions for all columns
- Document business logic in SQL comments
- Keep README.md up to date

### 4. Performance
- Use views for staging and intermediate layers
- Use tables for marts (final consumption)
- Add incremental materialization for large fact tables
- Partition large tables appropriately

### 5. Security
- Never commit credentials
- Use environment variables for all sensitive data
- Keep IAM permissions least-privilege
- Review security scans before merging

## Troubleshooting

### Connection Issues
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify S3 access
aws s3 ls s3://bandsintown-dbt-analytics/

# Test Athena connection
aws athena get-work-group --work-group bandsintown-dbt-dev
```

### Model Errors
```bash
# Clear cache
make clean

# Reinstall packages
make deps

# Try running with full refresh
make refresh
```

### CI/CD Issues
- Check GitHub Actions logs
- Verify secrets are configured
- Ensure branch protection rules are met
- Check AWS permissions

## Resources

- [dbt Documentation](https://docs.getdbt.com/)
- [dbt Best Practices](https://docs.getdbt.com/guides/best-practices)
- [Athena SQL Reference](https://docs.aws.amazon.com/athena/latest/ug/ddl-sql-reference.html)
- [Bandsintown Engineering Handbook](https://handbook.bandsintown.com/)

## Getting Help

- Slack: #data-platform
- Email: data-platform@bandsintown.com
- Office Hours: Tuesdays 2-3pm PT

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Help others learn and grow
- Follow engineering best practices

