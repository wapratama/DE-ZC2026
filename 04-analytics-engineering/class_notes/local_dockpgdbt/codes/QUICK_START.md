# Quick Start Guide - Module 4 Local Setup

## 🚀 Fast Track Setup (15 minutes)

This is the condensed version. For detailed instructions, see TASK_3_LOCAL_SETUP_GUIDE.md

---

## Prerequisites
- Docker Desktop installed
- Python 3.8+ installed
- 5GB free disk space

---

## Step-by-Step Setup

### 1. Start Docker Services (2 min)
```bash
cd module-04
docker-compose up -d
```

Wait for: `✅ Container postgres_ny_taxi  Started`

### 2. Create Virtual Environment (1 min)
```bash
# Already done from previous module setup!
source .venv/bin/activate
```

### 3. Install Python Dependencies (2 min)
```bash
uv pip install pandas sqlalchemy psycopg2-binary dbt-core dbt-postgres
```

### 4. Download Sample Data (3 min)
```bash
# Download just January 2019 for testing
mkdir -p data/raw
cd data/raw
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2019-01.csv.gz
gunzip yellow_tripdata_2019-01.csv.gz
cd ../..
```

### 5. Load Data into PostgreSQL (2 min)
```bash
python ingest_data.py \
    --table_name=yellow_taxi_trips \
    --csv_file=data/raw/yellow_tripdata_2019-01.csv
```

### 6. Initialize dbt Project (2 min)
```bash
# Create dbt project
dbt init taxi_rides_ny
# Select: 1 (postgres)

# Copy profile configuration
mkdir -p ~/.dbt
cp profiles.yml ~/.dbt/profiles.yml
```

### 7. Test Connection (1 min)
```bash
cd taxi_rides_ny
dbt debug
```

Should show: `✅ All checks passed!`

### 8. Create First Model (2 min)
```bash
mkdir -p models/staging

# Create source definition
cat > models/staging/schema.yml << 'EOF'
version: 2

sources:
  - name: staging
    database: ny_taxi
    schema: public
    tables:
      - name: yellow_taxi_trips
EOF

# Create staging model
cat > models/staging/stg_yellow_tripdata.sql << 'EOF'
{{ config(materialized='view') }}

select
    cast(vendorid as integer) as vendorid,
    cast(tpep_pickup_datetime as timestamp) as pickup_datetime,
    cast(tpep_dropoff_datetime as timestamp) as dropoff_datetime,
    cast(passenger_count as integer) as passenger_count,
    cast(trip_distance as numeric) as trip_distance,
    cast(fare_amount as numeric) as fare_amount,
    cast(total_amount as numeric) as total_amount,
    cast(payment_type as integer) as payment_type
    
from {{ source('staging', 'yellow_taxi_trips') }}
where tpep_pickup_datetime >= '2019-01-01'
EOF
```

### 9. Run dbt Model (1 min)
```bash
dbt run
```

Should show: `✅ Completed successfully`

### 10. Verify (1 min)
```bash
# Install pgcli
uv pip install pgcli

# Connect and query
pgcli -h localhost -p 5432 -u root -d ny_taxi

# In pgcli:
SELECT COUNT(*) FROM dbt_dev.stg_yellow_tripdata;
\q
```

---

## ✅ Setup Complete!

You now have:
- ✅ PostgreSQL database running
- ✅ Sample data loaded
- ✅ dbt installed and configured
- ✅ First model created and working

---

## Quick Reference

### Start/Stop Docker
```bash
docker-compose up -d      # Start
docker-compose down       # Stop
docker-compose ps         # Check status
```

### dbt Commands
```bash
dbt run                   # Run models
dbt test                  # Run tests
dbt docs generate         # Generate docs
dbt docs serve            # View docs (http://localhost:8080)
```

### Access Database
```bash
# CLI
pgcli -h localhost -p 5432 -u root -d ny_taxi

# GUI
http://localhost:8080
Username: admin@admin.com
Password: admin
```

---

## Troubleshooting

**Port 5432 already in use?**
```bash
sudo lsof -i :5432  # Find what's using it
sudo systemctl stop postgresql  # Stop local postgres
```

**dbt connection failed?**
```bash
dbt debug  # Check configuration
cat ~/.dbt/profiles.yml  # Verify settings
```

**Docker not starting?**
```bash
docker-compose logs postgres  # Check logs
docker-compose restart  # Restart services
```

---

## Next Steps

1. Load more data (2019-2020)
2. Create additional models
3. Add tests
4. Complete homework

See TASK_4 for homework solutions!
