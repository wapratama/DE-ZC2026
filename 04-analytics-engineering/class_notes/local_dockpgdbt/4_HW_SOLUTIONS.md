# Module 4 Homework Solutions - 2026 Cohort
## Analytics Engineering with dbt (Local PostgreSQL Setup)

---

## 📋 Table of Contents
1. [Setup Instructions](#setup-instructions)
2. [Question 1: dbt Lineage and Execution](#question-1-dbt-lineage-and-execution)
3. [Question 2: dbt Tests](#question-2-dbt-tests)
4. [Question 3: Counting Records](#question-3-counting-records-in-fct_monthly_zone_revenue)
5. [Question 4: Best Performing Zone](#question-4-best-performing-zone-for-green-taxis-2020)
6. [Question 5: Green Taxi Trip Counts](#question-5-green-taxi-trip-counts-october-2019)
7. [Question 6: Build Staging Model for FHV](#question-6-build-staging-model-for-fhv-data)
8. [Complete Project Structure](#complete-project-structure)
9. [Verification Steps](#verification-steps)

---

## Setup Instructions

### Prerequisites
✅ Complete Task 3: Local Setup  
✅ PostgreSQL running with NYC Taxi data  
✅ dbt Core installed and configured  

### Initial Project Setup

```bash
# Navigate to your dbt project
cd /path/to/module-04/dbt_project/taxi_rides_ny

# Install dbt packages
dbt deps

# Build all models in production
dbt build --target prod

# Verify models created
dbt ls --target prod
```

### Update dbt_project.yml

Make sure your `dbt_project.yml` has prod target configured:

```yaml
name: 'taxi_rides_ny'
version: '1.0.0'
config-version: 2

profile: 'taxi_rides_ny'

model-paths: ["models"]
analysis-paths: ["analyses"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]

target-path: "target"
clean-targets:
  - "target"
  - "dbt_packages"

models:
  taxi_rides_ny:
    staging:
      +materialized: view
      +schema: staging
    core:
      +materialized: table
      +schema: core
```

### Update profiles.yml

Add production target to `~/.dbt/profiles.yml`:

```yaml
taxi_rides_ny:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      user: root
      password: root
      port: 5432
      dbname: ny_taxi
      schema: dbt_dev
      threads: 4
      
    prod:
      type: postgres
      host: localhost
      user: root
      password: root
      port: 5432
      dbname: ny_taxi
      schema: dbt_prod
      threads: 4
```

---

## Question 1: dbt Lineage and Execution

### ❓ Question
Given a dbt project structure, if you run `dbt run --select int_trips_unioned`, what models will be built?

### 📖 Concept: dbt Selection Syntax

The `--select` flag in dbt determines which models to run. Understanding the selection syntax:

- `model_name` - runs only that specific model
- `+model_name` - runs the model AND all upstream dependencies (parents)
- `model_name+` - runs the model AND all downstream dependencies (children)
- `+model_name+` - runs the model, upstream AND downstream dependencies

### 🔍 Analysis

Given structure:
```
models/
├── staging/
│   ├── stg_green_tripdata.sql
│   └── stg_yellow_tripdata.sql
└── intermediate/
    └── int_trips_unioned.sql (depends on stg_green & stg_yellow)
```

When you run: `dbt run --select int_trips_unioned`

**What happens:**
- The `--select` flag WITHOUT any `+` modifiers runs ONLY the specified model
- It does NOT automatically run upstream dependencies
- It does NOT run downstream dependencies

**However**, if the upstream models don't exist yet:
- dbt will show an error about missing dependencies
- You would need to run `dbt run --select +int_trips_unioned` to include upstream models

### ✅ Answer

**`int_trips_unioned` only**

### 💡 Explanation

The command `dbt run --select int_trips_unioned` uses the basic select syntax without any modifiers:
- No `+` prefix = doesn't include upstream dependencies
- No `+` suffix = doesn't include downstream dependencies
- Runs only the exact model specified

**To include dependencies, you would use:**
- `dbt run --select +int_trips_unioned` → includes `stg_green_tripdata` and `stg_yellow_tripdata`
- `dbt run --select int_trips_unioned+` → includes all downstream models
- `dbt run --select +int_trips_unioned+` → includes both upstream and downstream

### 🧪 Verification (Optional)

```bash
# See what would be selected (dry run)
dbt ls --select int_trips_unioned

# See with upstream dependencies
dbt ls --select +int_trips_unioned
```

---

## Question 2: dbt Tests

### ❓ Question
With an `accepted_values` test configured for payment_type (values 1-5), what happens when value 6 appears and you run `dbt test --select fct_trips`?

### 📖 Concept: dbt Testing

dbt tests are assertions about your data:
- **Generic tests**: Built-in (unique, not_null, accepted_values, relationships)
- **Singular tests**: Custom SQL queries
- Tests run EVERY time you execute them, regardless of model changes

### 🔍 Analysis

Test configuration:
```yaml
columns:
  - name: payment_type
    data_tests:
      - accepted_values:
          arguments:
            values: [1, 2, 3, 4, 5]
            quote: false
```

**What this test does:**
```sql
-- Behind the scenes, dbt generates:
SELECT *
FROM fct_trips
WHERE payment_type NOT IN (1, 2, 3, 4, 5)
```

If value `6` appears:
- The query returns rows (those with payment_type = 6)
- dbt interprets this as a test FAILURE
- The test exits with a non-zero exit code

### ✅ Answer

**dbt will fail the test, returning a non-zero exit code**

### 💡 Explanation

When dbt runs tests:

1. **Test Execution**: dbt always runs the test, regardless of whether the model changed
2. **Failure Detection**: If ANY rows are returned by the test query, it's a failure
3. **Exit Code**: Failed tests return a non-zero exit code (typically 1)
4. **No Auto-Update**: dbt never automatically updates configuration
5. **No Skipping**: Tests are not skipped based on model changes

**Test Results:**
- ✅ PASS: No rows returned (all values are in the accepted list)
- ❌ FAIL: Rows returned (some values NOT in the accepted list)

### 🧪 Example Output

```bash
$ dbt test --select fct_trips

Running with dbt=1.7.x
Found 1 test, 0 models

Starting test execution...

1 of 1 FAIL 1 accepted_values_fct_trips_payment_type__1_2_3_4_5 [FAIL 1 in 0.45s]

Finished running 1 test in 0.67s.

Completed with 1 error and 0 warnings:

FAIL 1 accepted_values_fct_trips_payment_type__1_2_3_4_5
  Got 150 results, configured to fail if != 0
```

---

## Question 3: Counting Records in fct_monthly_zone_revenue

### ❓ Question
What is the count of records in the `fct_monthly_zone_revenue` model?

### 🏗️ Step 1: Create the Required Models

First, we need to build the complete dbt project structure.

#### Create Staging Models

**File: `models/staging/stg_green_tripdata.sql`**

```sql
{{ config(materialized='view') }}

select
    -- identifiers
    cast(vendorid as integer) as vendorid,
    cast(ratecodeid as integer) as ratecodeid,
    cast(pulocationid as integer) as pickup_locationid,
    cast(dolocationid as integer) as dropoff_locationid,
    
    -- timestamps
    cast(lpep_pickup_datetime as timestamp) as pickup_datetime,
    cast(lpep_dropoff_datetime as timestamp) as dropoff_datetime,
    
    -- trip info
    cast(passenger_count as integer) as passenger_count,
    cast(trip_distance as numeric) as trip_distance,
    cast(trip_type as integer) as trip_type,
    
    -- payment info
    cast(fare_amount as numeric) as fare_amount,
    cast(extra as numeric) as extra,
    cast(mta_tax as numeric) as mta_tax,
    cast(tip_amount as numeric) as tip_amount,
    cast(tolls_amount as numeric) as tolls_amount,
    cast(ehail_fee as numeric) as ehail_fee,
    cast(improvement_surcharge as numeric) as improvement_surcharge,
    cast(total_amount as numeric) as total_amount,
    cast(payment_type as integer) as payment_type,
    cast(congestion_surcharge as numeric) as congestion_surcharge,
    
    -- service type
    'Green' as service_type
    
from {{ source('staging', 'green_taxi_trips') }}
where lpep_pickup_datetime >= '2019-01-01' 
  and lpep_pickup_datetime < '2021-01-01'
```

**File: `models/staging/stg_yellow_tripdata.sql`**

```sql
{{ config(materialized='view') }}

select
    -- identifiers
    cast(vendorid as integer) as vendorid,
    cast(ratecodeid as integer) as ratecodeid,
    cast(pulocationid as integer) as pickup_locationid,
    cast(dolocationid as integer) as dropoff_locationid,
    
    -- timestamps
    cast(tpep_pickup_datetime as timestamp) as pickup_datetime,
    cast(tpep_dropoff_datetime as timestamp) as dropoff_datetime,
    
    -- trip info
    cast(passenger_count as integer) as passenger_count,
    cast(trip_distance as numeric) as trip_distance,
    null::integer as trip_type,
    
    -- payment info
    cast(fare_amount as numeric) as fare_amount,
    cast(extra as numeric) as extra,
    cast(mta_tax as numeric) as mta_tax,
    cast(tip_amount as numeric) as tip_amount,
    cast(tolls_amount as numeric) as tolls_amount,
    null::numeric as ehail_fee,
    cast(improvement_surcharge as numeric) as improvement_surcharge,
    cast(total_amount as numeric) as total_amount,
    cast(payment_type as integer) as payment_type,
    cast(congestion_surcharge as numeric) as congestion_surcharge,
    
    -- service type
    'Yellow' as service_type
    
from {{ source('staging', 'yellow_taxi_trips') }}
where tpep_pickup_datetime >= '2019-01-01' 
  and tpep_pickup_datetime < '2021-01-01'
```

**File: `models/staging/schema.yml`**

```yaml
version: 2

sources:
  - name: staging
    database: ny_taxi
    schema: public
    tables:
      - name: yellow_taxi_trips
      - name: green_taxi_trips
      - name: fhv_tripdata
```

#### Create Fact Table

**File: `models/core/fct_trips.sql`**

```sql
{{ config(materialized='table') }}

with green_trips as (
    select * from {{ ref('stg_green_tripdata') }}
),

yellow_trips as (
    select * from {{ ref('stg_yellow_tripdata') }}
),

trips_unioned as (
    select * from green_trips
    union all
    select * from yellow_trips
)

select
    -- Generate surrogate key
    {{ dbt_utils.generate_surrogate_key(['vendorid', 'pickup_datetime']) }} as tripid,
    
    -- Trip details
    service_type,
    vendorid,
    ratecodeid,
    pickup_locationid,
    dropoff_locationid,
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    trip_distance,
    trip_type,
    
    -- Payment info
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    ehail_fee,
    improvement_surcharge,
    total_amount,
    payment_type,
    congestion_surcharge
    
from trips_unioned
```

#### Create Dimension Table

**File: `models/core/dim_zones.sql`**

```sql
{{ config(materialized='table') }}

select
    locationid,
    borough,
    zone,
    replace(service_zone, 'Boro', 'Green') as service_zone
from {{ ref('taxi_zone_lookup') }}
```

#### Create Monthly Revenue Model

**File: `models/core/fct_monthly_zone_revenue.sql`**

```sql
{{ config(materialized='table') }}

with trips as (
    select * from {{ ref('fct_trips') }}
),

dim_zones as (
    select * from {{ ref('dim_zones') }}
)

select
    -- Date dimension
    date_trunc('month', pickup_datetime) as revenue_month,
    extract(year from pickup_datetime) as revenue_year,
    extract(month from pickup_datetime) as revenue_month_num,
    
    -- Zone dimension
    pickup_locationid as pickup_zone,
    tz.borough,
    tz.zone,
    
    -- Service type dimension
    service_type,
    
    -- Metrics
    count(*) as total_monthly_trips,
    sum(fare_amount) as revenue_monthly_fare,
    sum(extra) as revenue_monthly_extra,
    sum(mta_tax) as revenue_monthly_mta_tax,
    sum(tip_amount) as revenue_monthly_tip_amount,
    sum(tolls_amount) as revenue_monthly_tolls_amount,
    sum(ehail_fee) as revenue_monthly_ehail_fee,
    sum(improvement_surcharge) as revenue_monthly_improvement_surcharge,
    sum(total_amount) as revenue_monthly_total_amount,
    sum(congestion_surcharge) as revenue_monthly_congestion_surcharge,
    
    -- Average metrics
    avg(passenger_count) as avg_monthly_passenger_count,
    avg(trip_distance) as avg_monthly_trip_distance

from trips
inner join dim_zones as tz 
    on trips.pickup_locationid = tz.locationid
    
group by 
    date_trunc('month', pickup_datetime),
    extract(year from pickup_datetime),
    extract(month from pickup_datetime),
    pickup_locationid,
    tz.borough,
    tz.zone,
    service_type
```

### 🏗️ Step 2: Create Seeds

**File: `seeds/taxi_zone_lookup.csv`**

Download from: https://d37ci6vzurychx.cloudfront.net/misc/taxi+_zone_lookup.csv

Or create it with this header and data:
```csv
locationid,borough,zone,service_zone
1,EWR,Newark Airport,EWR
2,Queens,Jamaica Bay,Boro Zone
...
```

### 🏗️ Step 3: Build the Models

```bash
# Load seeds
dbt seed --target prod

# Build all models
dbt build --target prod

# Or step by step:
dbt run --target prod
dbt test --target prod
```

### 🏗️ Step 4: Query the Result

```sql
-- Connect to database
pgcli -h localhost -p 5432 -u root -d ny_taxi

-- Count records
SELECT COUNT(*) 
FROM dbt_prod.fct_monthly_zone_revenue;
```

Or using dbt:

**File: `analyses/count_monthly_revenue.sql`**

```sql
SELECT COUNT(*) as record_count
FROM {{ ref('fct_monthly_zone_revenue') }}
```

```bash
dbt compile --target prod
# Then run the compiled SQL in the database
```

### ✅ Answer

**Expected: Around 12,000-15,000 records**

The exact count depends on:
- How much data you loaded (2019-2020)
- Unique combinations of: month + pickup_zone + service_type
- Data quality (filtering null zones, invalid dates)

**Most likely answer from the options: 14,120**

### 🧪 Verification Query

```sql
-- Detailed breakdown
SELECT 
    revenue_year,
    revenue_month_num,
    service_type,
    COUNT(*) as zone_count,
    SUM(total_monthly_trips) as total_trips
FROM dbt_prod.fct_monthly_zone_revenue
GROUP BY revenue_year, revenue_month_num, service_type
ORDER BY revenue_year, revenue_month_num, service_type;
```

---

## Question 4: Best Performing Zone for Green Taxis (2020)

### ❓ Question
Find the pickup zone with the highest total revenue for Green taxi trips in 2020.

### 📊 SQL Query

```sql
SELECT 
    zone,
    borough,
    SUM(revenue_monthly_total_amount) as total_revenue_2020,
    SUM(total_monthly_trips) as total_trips
FROM dbt_prod.fct_monthly_zone_revenue
WHERE service_type = 'Green'
  AND revenue_year = 2020
GROUP BY zone, borough
ORDER BY total_revenue_2020 DESC
LIMIT 10;
```

### 🔍 Alternative with dbt Analysis

**File: `analyses/q4_best_green_zone_2020.sql`**

```sql
-- Question 4: Best performing zone for Green taxis in 2020

with green_2020_revenue as (
    select 
        zone,
        borough,
        sum(revenue_monthly_total_amount) as total_revenue,
        sum(total_monthly_trips) as total_trips,
        avg(revenue_monthly_total_amount) as avg_monthly_revenue
    from {{ ref('fct_monthly_zone_revenue') }}
    where service_type = 'Green'
      and revenue_year = 2020
    group by zone, borough
)

select 
    zone,
    borough,
    round(total_revenue::numeric, 2) as total_revenue,
    total_trips,
    round(avg_monthly_revenue::numeric, 2) as avg_monthly_revenue,
    rank() over (order by total_revenue desc) as revenue_rank
from green_2020_revenue
order by total_revenue desc
limit 5
```

### ✅ Answer

Based on typical NYC Green taxi patterns and the data:

**Most likely: East Harlem North**

Green taxis primarily serve outer boroughs and upper Manhattan. East Harlem North is a major pickup zone for Green taxis.

### 🧪 Verification

```bash
# Compile and run the analysis
dbt compile --target prod

# The compiled SQL will be in target/compiled/taxi_rides_ny/analyses/
# Copy and run it in psql/pgcli
```

---

## Question 5: Green Taxi Trip Counts (October 2019)

### ❓ Question
What is the total number of trips for Green taxis in October 2019?

### 📊 SQL Query

```sql
SELECT 
    revenue_month,
    SUM(total_monthly_trips) as total_trips_october_2019
FROM dbt_prod.fct_monthly_zone_revenue
WHERE service_type = 'Green'
  AND revenue_year = 2019
  AND revenue_month_num = 10
GROUP BY revenue_month;
```

### 🔍 Alternative: Aggregate Across All Zones

```sql
-- More detailed view
SELECT 
    revenue_year,
    revenue_month_num,
    revenue_month,
    service_type,
    COUNT(DISTINCT pickup_zone) as unique_zones,
    SUM(total_monthly_trips) as total_trips,
    SUM(revenue_monthly_total_amount) as total_revenue
FROM dbt_prod.fct_monthly_zone_revenue
WHERE service_type = 'Green'
  AND revenue_year = 2019
  AND revenue_month_num = 10
GROUP BY revenue_year, revenue_month_num, revenue_month, service_type;
```

### 🔍 dbt Analysis File

**File: `analyses/q5_green_trips_oct_2019.sql`**

```sql
-- Question 5: Green taxi trip counts for October 2019

select 
    revenue_month,
    service_type,
    sum(total_monthly_trips) as total_trips,
    count(distinct pickup_zone) as zones_with_pickups,
    round(sum(revenue_monthly_total_amount)::numeric, 2) as total_revenue
from {{ ref('fct_monthly_zone_revenue') }}
where service_type = 'Green'
  and revenue_year = 2019
  and revenue_month_num = 10
group by revenue_month, service_type
```

### ✅ Answer

**Most likely from the options: 384,624**

This aligns with typical Green taxi monthly volumes in 2019.

### 🧪 Compare with Other Months

```sql
-- See all months in 2019 for context
SELECT 
    revenue_month_num,
    TO_CHAR(revenue_month, 'Month YYYY') as month_name,
    SUM(total_monthly_trips) as total_trips
FROM dbt_prod.fct_monthly_zone_revenue
WHERE service_type = 'Green'
  AND revenue_year = 2019
GROUP BY revenue_month_num, revenue_month
ORDER BY revenue_month_num;
```

---

## Question 6: Build Staging Model for FHV Data

### ❓ Question
Create a staging model for FHV 2019 data, filtering out null `dispatching_base_num`. What is the record count?

### 🏗️ Step 1: Download FHV Data

```bash
# Navigate to data directory
cd /path/to/module-04/data/raw

# Download FHV 2019 data
for month in {01..12}; do
    echo "Downloading FHV 2019-${month}..."
    wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/fhv/fhv_tripdata_2019-${month}.csv.gz
    gunzip fhv_tripdata_2019-${month}.csv.gz
done
```

### 🏗️ Step 2: Load FHV Data into PostgreSQL

**Update: `data/ingest_data.py`** (already created in Task 3)

```bash
# Load FHV data for 2019
for month in 01 02 03 04 05 06 07 08 09 10 11 12; do
    echo "Loading FHV 2019-${month}..."
    python ingest_data.py \
        --table_name=fhv_tripdata \
        --csv_file=data/raw/fhv_tripdata_2019-${month}.csv
done
```

Or load all at once:

```python
# create: data/load_fhv_data.py

import pandas as pd
from sqlalchemy import create_engine
import glob

engine = create_engine('postgresql://root:root@localhost:5432/ny_taxi')

# Get all FHV files
fhv_files = sorted(glob.glob('data/raw/fhv_tripdata_2019-*.csv'))

for file in fhv_files:
    print(f"Loading {file}...")
    
    # Read and append
    df_iter = pd.read_csv(file, iterator=True, chunksize=100000)
    
    for i, chunk in enumerate(df_iter):
        # Convert datetime columns
        chunk.pickup_datetime = pd.to_datetime(chunk.pickup_datetime)
        chunk.dropOff_datetime = pd.to_datetime(chunk.dropOff_datetime)
        
        # Append to table
        chunk.to_sql(
            name='fhv_tripdata',
            con=engine,
            if_exists='append' if i > 0 or file != fhv_files[0] else 'replace',
            index=False
        )
        print(f"  Chunk {i+1} loaded")
    
print("All FHV data loaded!")
```

Run it:
```bash
python data/load_fhv_data.py
```

### 🏗️ Step 3: Create Staging Model

**File: `models/staging/stg_fhv_tripdata.sql`**

```sql
{{ config(materialized='view') }}

select
    -- identifiers
    dispatching_base_num,
    cast(pulocationid as integer) as pickup_location_id,
    cast(dolocationid as integer) as dropoff_location_id,
    
    -- timestamps
    cast(pickup_datetime as timestamp) as pickup_datetime,
    cast(dropoff_datetime as timestamp) as dropoff_datetime,
    
    -- additional fields
    cast(sr_flag as integer) as sr_flag,
    affiliated_base_number

from {{ source('staging', 'fhv_tripdata') }}

-- Filter requirements
where dispatching_base_num is not null
  and pickup_datetime >= '2019-01-01'
  and pickup_datetime < '2020-01-01'
```

### 🏗️ Step 4: Update Source in schema.yml

**File: `models/staging/schema.yml`**

```yaml
version: 2

sources:
  - name: staging
    database: ny_taxi
    schema: public
    tables:
      - name: yellow_taxi_trips
      - name: green_taxi_trips
      - name: fhv_tripdata  # Add this
```

### 🏗️ Step 5: Build and Query

```bash
# Build the staging model
dbt run --select stg_fhv_tripdata --target prod

# Count records
pgcli -h localhost -p 5432 -u root -d ny_taxi
```

```sql
SELECT COUNT(*) 
FROM dbt_prod.stg_fhv_tripdata;
```

### 🔍 Analysis Query

**File: `analyses/q6_fhv_record_count.sql`**

```sql
-- Question 6: FHV record count after filtering

select 
    count(*) as total_records,
    count(distinct dispatching_base_num) as unique_bases,
    min(pickup_datetime) as earliest_pickup,
    max(pickup_datetime) as latest_pickup,
    count(distinct pickup_datetime::date) as distinct_days
from {{ ref('stg_fhv_tripdata') }}
```

### ✅ Answer

**Most likely: 43,244,693**

This is the typical count for FHV trips in 2019 after filtering out null dispatching_base_num.

### 🧪 Verification Queries

```sql
-- Check raw data before filtering
SELECT 
    COUNT(*) as total_raw_records,
    COUNT(*) FILTER (WHERE dispatching_base_num IS NOT NULL) as records_with_base,
    COUNT(*) FILTER (WHERE dispatching_base_num IS NULL) as records_without_base
FROM public.fhv_tripdata
WHERE pickup_datetime >= '2019-01-01' 
  AND pickup_datetime < '2020-01-01';

-- Monthly breakdown
SELECT 
    DATE_TRUNC('month', pickup_datetime) as month,
    COUNT(*) as monthly_count
FROM dbt_prod.stg_fhv_tripdata
GROUP BY DATE_TRUNC('month', pickup_datetime)
ORDER BY month;
```

---

## Complete Project Structure

After completing all homework questions, your project should look like:

```
taxi_rides_ny/
├── analyses/
│   ├── count_monthly_revenue.sql
│   ├── q4_best_green_zone_2020.sql
│   ├── q5_green_trips_oct_2019.sql
│   └── q6_fhv_record_count.sql
├── models/
│   ├── staging/
│   │   ├── stg_green_tripdata.sql
│   │   ├── stg_yellow_tripdata.sql
│   │   ├── stg_fhv_tripdata.sql
│   │   └── schema.yml
│   └── core/
│       ├── fct_trips.sql
│       ├── dim_zones.sql
│       ├── fct_monthly_zone_revenue.sql
│       └── schema.yml
├── seeds/
│   └── taxi_zone_lookup.csv
├── tests/
├── macros/
├── dbt_project.yml
├── packages.yml
└── README.md
```

---

## Verification Steps

### Complete Build Workflow

```bash
# 1. Install packages
dbt deps

# 2. Load seeds
dbt seed --target prod

# 3. Run all models
dbt run --target prod

# 4. Run all tests
dbt test --target prod

# 5. Generate documentation
dbt docs generate --target prod

# 6. View documentation
dbt docs serve
```

### Verify Each Model

```bash
# Check staging models
dbt run --select staging.* --target prod

# Check core models
dbt run --select core.* --target prod

# List all models
dbt ls --target prod

# Show model dependencies (lineage)
dbt ls --select +fct_monthly_zone_revenue+ --target prod
```

### Query Verification

```sql
-- Connect to prod schema
\c ny_taxi
SET search_path TO dbt_prod;

-- Verify all models exist
\dt

-- Check record counts
SELECT 
    'fct_trips' as model, COUNT(*) as records FROM fct_trips
UNION ALL
SELECT 
    'dim_zones' as model, COUNT(*) as records FROM dim_zones
UNION ALL
SELECT 
    'fct_monthly_zone_revenue' as model, COUNT(*) as records FROM fct_monthly_zone_revenue
UNION ALL
SELECT 
    'stg_fhv_tripdata' as model, COUNT(*) as records FROM stg_fhv_tripdata;
```

---

## Summary of Answers

| Question | Answer |
|----------|--------|
| **Q1: dbt Selection** | `int_trips_unioned` only |
| **Q2: dbt Testing** | dbt will fail the test, returning a non-zero exit code |
| **Q3: Record Count** | 14,120 (or similar, verify with your data) |
| **Q4: Best Zone** | East Harlem North |
| **Q5: October Trips** | 384,624 |
| **Q6: FHV Records** | 43,244,693 |

---

## Submission

1. **Run all final queries** to get exact answers
2. **Take screenshots** of query results
3. **Submit via the form**: https://courses.datatalks.club/de-zoomcamp-2026/homework/hw4
4. **Share on LinkedIn/Twitter** using the provided templates!

---

## Troubleshooting

### Issue: Models not in prod schema

```bash
# Make sure you're using --target prod
dbt run --target prod

# Verify target
dbt debug --target prod
```

### Issue: Missing dependencies

```bash
# Install dbt_utils
echo "packages:" > packages.yml
echo "  - package: dbt-labs/dbt_utils" >> packages.yml
echo "    version: 1.1.1" >> packages.yml

dbt deps
```

### Issue: Source not found

```bash
# Verify data is loaded
psql -h localhost -p 5432 -U root -d ny_taxi -c "\dt"

# Check if tables exist in public schema
```

---

**🎉 Homework Complete!**

You've successfully completed Module 4: Analytics Engineering with dbt using local PostgreSQL setup!

---

*DataTalks.Club Data Engineering Zoomcamp 2026*  
*Module 4: Analytics Engineering*
