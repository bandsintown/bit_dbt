# dbt with S3/Athena - Example Usage

This guide shows how dbt connects to S3 data via Athena and transforms it.

## 🔄 How It Works

### 1. Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                        S3 Storage                           │
│                                                             │
│  s3://bandsintown-raw-data/                                │
│    └── events/                                             │
│        ├── 2024-01-01/events.parquet                      │
│        ├── 2024-01-02/events.parquet                      │
│        └── ...                                             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    AWS Glue Catalog                         │
│                                                             │
│  Database: bandsintown_raw                                 │
│    Table: events                                           │
│      - Points to S3 location                               │
│      - Defines schema (event_id, artist_id, etc.)          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      dbt Source                             │
│                                                             │
│  File: models/staging/.../src_bandsintown_raw.yml          │
│  Defines: source('bandsintown_raw', 'events')              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   dbt Transformation                        │
│                                                             │
│  File: models/staging/.../stg_events.sql                   │
│  - Reads from source via Athena                            │
│  - Cleans and transforms data                              │
│  - Adds calculated fields                                  │
│  - Filters invalid records                                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                    Result in Athena                         │
│                                                             │
│  Database: bandsintown_analytics_dev                       │
│    View: stg_events                                        │
│      - Materialized as Athena view                         │
│      - Data stays in S3                                    │
│      - Queryable via Athena                                │
└─────────────────────────────────────────────────────────────┘
```

## 📝 Example: Staging Events Model

### Source Definition

**File**: `models/staging/bandsintown_raw/src_bandsintown_raw.yml`

```yaml
sources:
  - name: bandsintown_raw
    description: Raw data in S3
    database: "{{ env_var('RAW_DATA_DATABASE', 'bandsintown_raw') }}"
    schema: bandsintown_raw
    
    tables:
      - name: events
        description: Raw events data
        # This points to a Glue table that references S3 data
```

### Transformation Model

**File**: `models/staging/bandsintown_raw/stg_events.sql`

```sql
{{
    config(
        materialized='view',  -- Creates an Athena view
        tags=['staging', 'events']
    )
}}

with source as (
    
    -- This queries S3 data via Athena
    select * from {{ source('bandsintown_raw', 'events') }}

),

renamed as (

    select
        -- Primary key
        event_id,
        
        -- Foreign keys
        artist_id,
        venue_id,
        
        -- Event details
        event_date,
        event_status,
        ticket_url,
        
        -- Metadata
        created_at,
        updated_at,
        
        -- Calculated fields (computed during query)
        cast(event_date as date) as event_date_only,
        date_format(event_date, '%Y-%m') as event_month,
        year(event_date) as event_year,
        
        -- Data quality flags
        case
            when event_status in ('upcoming', 'cancelled', 'postponed', 'past') 
            then true
            else false
        end as is_valid_status

    from source
    
    -- Filter out invalid data
    where event_id is not null
        and artist_id is not null
        and event_date is not null

)

select * from renamed
```

## 🚀 Running the Example

### Step 1: Setup Prerequisites

```bash
# 1. Create S3 bucket for raw data
aws s3 mb s3://bandsintown-raw-data

# 2. Create S3 bucket for analytics
aws s3 mb s3://bandsintown-dbt-analytics

# 3. Create Glue database for raw data
aws glue create-database \
  --database-input '{"Name": "bandsintown_raw"}'

# 4. Create Glue database for analytics
aws glue create-database \
  --database-input '{"Name": "bandsintown_analytics_dev"}'
```

### Step 2: Create Sample Data

```bash
# Create sample events data
cat > /tmp/sample_events.json << 'EOF'
{"event_id": "1", "artist_id": "a1", "venue_id": "v1", "event_date": "2024-06-01T19:00:00", "event_status": "upcoming", "ticket_url": "http://example.com", "created_at": "2024-05-01T10:00:00", "updated_at": "2024-05-01T10:00:00"}
{"event_id": "2", "artist_id": "a2", "venue_id": "v2", "event_date": "2024-06-15T20:00:00", "event_status": "upcoming", "ticket_url": "http://example.com", "created_at": "2024-05-02T10:00:00", "updated_at": "2024-05-02T10:00:00"}
{"event_id": "3", "artist_id": "a3", "venue_id": "v3", "event_date": "2024-07-01T21:00:00", "event_status": "upcoming", "ticket_url": "http://example.com", "created_at": "2024-05-03T10:00:00", "updated_at": "2024-05-03T10:00:00"}
EOF

# Upload to S3
aws s3 cp /tmp/sample_events.json s3://bandsintown-raw-data/events/
```

### Step 3: Create Glue Table

```sql
-- Run this in Athena console
CREATE EXTERNAL TABLE IF NOT EXISTS bandsintown_raw.events (
    event_id string,
    artist_id string,
    venue_id string,
    event_date timestamp,
    event_status string,
    ticket_url string,
    created_at timestamp,
    updated_at timestamp
)
ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
LOCATION 's3://bandsintown-raw-data/events/';
```

### Step 4: Configure dbt

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your settings
nano .env
```

**Update these values in `.env`**:
```bash
AWS_REGION=us-east-1
DBT_ATHENA_S3_STAGING_DIR=s3://bandsintown-dbt-analytics/dev/
DBT_ATHENA_S3_DATA_DIR=s3://bandsintown-dbt-analytics/dev/data/
DBT_ATHENA_DATABASE=bandsintown_analytics_dev
DBT_ATHENA_WORKGROUP=primary
RAW_DATA_DATABASE=bandsintown_raw
```

### Step 5: Run dbt

```bash
# Setup environment
./scripts/setup.sh

# Activate virtual environment
source .venv/bin/activate

# Test connection
dbt debug

# Expected output:
# Connection test: [OK connection ok]

# Run the staging model
dbt run --select stg_events

# Expected output:
# Completed successfully
# CREATE VIEW bandsintown_analytics_dev.stg_events
```

### Step 6: Query Results

```bash
# Query the transformed data via Athena
aws athena start-query-execution \
  --query-string "SELECT * FROM bandsintown_analytics_dev.stg_events LIMIT 10" \
  --result-configuration "OutputLocation=s3://bandsintown-dbt-analytics/dev/queries/" \
  --query-execution-context "Database=bandsintown_analytics_dev"
```

Or in Athena Console:
```sql
-- View the transformed data
SELECT 
    event_id,
    artist_id,
    event_date_only,
    event_month,
    event_year,
    event_status,
    is_valid_status
FROM bandsintown_analytics_dev.stg_events
LIMIT 10;
```

## 🔍 What's Happening Behind the Scenes

### When you run `dbt run`:

1. **dbt reads** your SQL model file (`stg_events.sql`)
2. **dbt compiles** the Jinja/SQL into pure SQL
3. **dbt connects** to Athena using credentials from `profiles.yml`
4. **dbt executes** `CREATE VIEW` statement in Athena
5. **Athena creates** a view in the Glue Catalog
6. **The view definition** references the source S3 data
7. **When queried**, Athena reads from S3 and applies transformations

### Example Compiled SQL:

```sql
CREATE OR REPLACE VIEW bandsintown_analytics_dev.stg_events AS

WITH source AS (
    SELECT * FROM bandsintown_raw.events
),

renamed AS (
    SELECT
        event_id,
        artist_id,
        venue_id,
        event_date,
        event_status,
        ticket_url,
        created_at,
        updated_at,
        CAST(event_date AS date) AS event_date_only,
        date_format(event_date, '%Y-%m') AS event_month,
        year(event_date) AS event_year,
        CASE
            WHEN event_status IN ('upcoming', 'cancelled', 'postponed', 'past') 
            THEN true
            ELSE false
        END AS is_valid_status
    FROM source
    WHERE event_id IS NOT NULL
        AND artist_id IS NOT NULL
        AND event_date IS NOT NULL
)

SELECT * FROM renamed;
```

## 💡 Key Concepts

### 1. **S3 as Data Storage**
- Raw data lives in S3 (cheap, scalable)
- No need to load into a database
- Data is queried in-place

### 2. **Glue Catalog as Metadata**
- Defines table schemas
- Points to S3 locations
- Acts like a database catalog

### 3. **Athena as Query Engine**
- Serverless query service
- Reads directly from S3
- No infrastructure to manage
- Pay only for queries run

### 4. **dbt as Transformation Layer**
- Defines transformations in SQL
- Creates views/tables in Athena
- Manages dependencies
- Runs tests on data
- Generates documentation

## 🎯 Benefits of This Approach

✅ **Cost Effective**
- No database infrastructure
- Pay only for Athena queries
- S3 storage is cheap

✅ **Scalable**
- Handle petabytes of data
- No capacity planning
- Automatically scales

✅ **Flexible**
- Query data in place
- Support multiple file formats
- Easy to add new sources

✅ **Version Controlled**
- All transformations in Git
- Reviewable changes
- Auditable history

## 📊 Performance Tips

1. **Partition your S3 data**
   ```
   s3://bucket/events/year=2024/month=01/day=01/
   ```

2. **Use columnar formats** (Parquet, ORC)
   - Faster queries
   - Lower costs

3. **Materialize as tables** for frequently accessed data
   ```sql
   {{ config(materialized='table') }}
   ```

4. **Use incremental models** for large datasets
   ```sql
   {{ config(materialized='incremental') }}
   ```

## 🔗 Additional Resources

- **dbt Documentation**: https://docs.getdbt.com/
- **Athena User Guide**: https://docs.aws.amazon.com/athena/
- **Glue Catalog**: https://docs.aws.amazon.com/glue/
- **dbt-athena Adapter**: https://github.com/dbt-athena/dbt-athena

---

**That's it!** You now have dbt transforming S3 data via Athena. 🎉

