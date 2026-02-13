# Module 4: Analytics Engineering - Complete Local Setup Guide

## 📋 TASK 3: DETAILED LOCAL SETUP - STEP BY STEP

---

## Table of Contents
1. [Prerequisites Check](#prerequisites-check)
2. [System Requirements](#system-requirements)
3. [Setup Overview](#setup-overview)
4. [Step-by-Step Installation](#step-by-step-installation)
5. [Verification & Testing](#verification-testing)
6. [Common Issues & Solutions](#common-issues-solutions)
7. [Quick Reference Commands](#quick-reference-commands)

---

## Prerequisites Check

Before starting, ensure you have:

### Required Software:
- ✅ **Docker Desktop** (version 20.10+)
- ✅ **Python** (version 3.8 or higher)
- ✅ **Git** (for cloning repositories)
- ✅ **Text Editor** (VS Code recommended)
- ✅ **Terminal/Command Line** access

### Optional but Recommended:
- ⭐ **pgAdmin** or **DBeaver** (GUI for PostgreSQL)
- ⭐ **pgcli** (CLI tool for PostgreSQL)
- ⭐ **UV** (fast Python package manager - already set up!)

---

## System Requirements

### Minimum Requirements:
- **RAM**: 8GB (16GB recommended)
- **Disk Space**: 5GB free
- **OS**: Windows 10/11, macOS 10.14+, or Linux
- **Internet**: For initial downloads only

### Estimated Setup Time:
- First-time setup: **30-40 minutes**
- If Docker already installed: **20-25 minutes**

---

## Setup Overview

### Architecture We're Building:

```
┌────────────────────────────────────────────────────────┐
│                  Your Local Machine                     │
├────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Docker Compose Network                    │  │
│  │                                                   │  │
│  │  ┌────────────────┐      ┌──────────────────┐   │  │
│  │  │   PostgreSQL   │◄────►│   pgAdmin        │   │  │
│  │  │   Container    │      │   Container      │   │  │
│  │  │  Port: 5432    │      │   Port: 8080     │   │  │
│  │  └────────────────┘      └──────────────────┘   │  │
│  │         ▲                                         │  │
│  └─────────┼─────────────────────────────────────────┘  │
│            │                                             │
│            │ SQL Connection                              │
│            │                                             │
│  ┌─────────▼─────────────────────────────────────────┐  │
│  │         dbt Core (Python Virtual Env)             │  │
│  │         - dbt-core                                │  │
│  │         - dbt-postgres                            │  │
│  └───────────────────────────────────────────────────┘  │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### What We'll Install:
1. Docker Desktop (if not installed)
2. PostgreSQL database (via Docker)
3. pgAdmin web interface (via Docker)
4. Python virtual environment with UV
5. dbt Core with PostgreSQL adapter
6. NYC Taxi dataset (2019-2020)

---

## Step-by-Step Installation

### STEP 1: Install Docker Desktop

#### For Windows:

1. **Download Docker Desktop**
   ```
   URL: https://www.docker.com/products/docker-desktop/
   ```

2. **Install Docker Desktop**
   - Run the installer
   - Enable WSL 2 if prompted
   - Restart computer if required

3. **Verify Installation**
   ```bash
   docker --version
   docker-compose --version
   ```
   
   Expected output:
   ```
   Docker version 24.0.x
   Docker Compose version v2.x.x
   ```

#### For macOS:

1. **Download Docker Desktop**
   ```
   URL: https://www.docker.com/products/docker-desktop/
   ```

2. **Install Docker Desktop**
   - Open the `.dmg` file
   - Drag Docker to Applications
   - Launch Docker from Applications

3. **Verify Installation**
   ```bash
   docker --version
   docker-compose --version
   ```

#### For Linux (Ubuntu/Debian):

```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up repository
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group (to run without sudo)
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

---

### STEP 2: Create Project Structure

Navigate to your module-4 directory (from your earlier setup):

```bash
# Navigate to module-4
cd /path/to/your/module-4

# Create project structure
mkdir -p {data,docker,dbt_project}

# Your structure should look like:
# module-4/
# ├── .venv/                    # Virtual environment (already exists)
# ├── data/                     # For CSV files
# ├── docker/                   # For Docker configs
# │   └── docker-compose.yml
# └── dbt_project/              # For dbt project files
```

---

### STEP 3: Create Docker Compose Configuration

Create `docker/docker-compose.yml`:

```yaml
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    container_name: postgres_ny_taxi
    image: postgres:13
    environment:
      POSTGRES_USER: root
      POSTGRES_PASSWORD: root
      POSTGRES_DB: ny_taxi
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ../data:/data  # Mount data directory
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U root"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - ny_taxi_network

  # pgAdmin Web Interface
  pgadmin:
    container_name: pgadmin_ny_taxi
    image: dpage/pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@admin.com
      PGADMIN_DEFAULT_PASSWORD: admin
    ports:
      - "8080:80"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - ny_taxi_network

volumes:
  postgres_data:
    driver: local

networks:
  ny_taxi_network:
    driver: bridge
```

**Save this file as**: `docker/docker-compose.yml`

---

### STEP 4: Start Docker Services

```bash
# Navigate to docker directory
cd docker

# Start services (first time will download images ~500MB)
docker-compose up -d

# Check if services are running
docker-compose ps

# You should see both services as "Up"
```

Expected output:
```
NAME                  IMAGE            STATUS         PORTS
postgres_ny_taxi      postgres:13      Up 30 seconds  0.0.0.0:5432->5432/tcp
pgadmin_ny_taxi       dpage/pgadmin4   Up 30 seconds  0.0.0.0:8080->80/tcp
```

**Troubleshooting**: If port 5432 is already in use:
```bash
# Check what's using port 5432
sudo lsof -i :5432  # macOS/Linux
netstat -ano | findstr :5432  # Windows

# Stop local PostgreSQL if running
sudo systemctl stop postgresql  # Linux
# Or stop from Services app on Windows
```

---

### STEP 5: Verify PostgreSQL Connection

#### Option A: Using pgcli (Recommended for CLI)

```bash
# Install pgcli if not already installed
pip install pgcli

# Connect to database
pgcli -h localhost -p 5432 -u root -d ny_taxi

# When prompted, enter password: root
```

Inside pgcli:
```sql
-- List databases
\l

-- List tables (should be empty for now)
\dt

-- Exit
\q
```

#### Option B: Using pgAdmin (Web Interface)

1. **Open pgAdmin**
   ```
   URL: http://localhost:8080
   ```

2. **Login**
   - Email: `admin@admin.com`
   - Password: `admin`

3. **Add Server Connection**
   - Right-click "Servers" → "Create" → "Server"
   - **General tab**:
     - Name: `NY Taxi Local`
   - **Connection tab**:
     - Host: `postgres` (container name, not localhost!)
     - Port: `5432`
     - Maintenance database: `ny_taxi`
     - Username: `root`
     - Password: `root`
     - Save password: ✓
   - Click "Save"

4. **Verify Connection**
   - Expand: Servers → NY Taxi Local → Databases → ny_taxi
   - Should see empty database ready for data

---

### STEP 6: Download NYC Taxi Dataset

We'll download Yellow and Green taxi data for 2019-2020:

#### Create Download Script

Create `data/download_data.sh`:

```bash
#!/bin/bash

# Script to download NYC Taxi data for 2019-2020

echo "Starting NYC Taxi Data Download..."
echo "This will download ~2GB of data"

# Create data directory if it doesn't exist
mkdir -p ../data/raw

cd ../data/raw

# Download Yellow Taxi Data (2019)
echo "Downloading Yellow Taxi 2019 data..."
for month in $(seq -f "%02g" 1 12); do
    wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2019-${month}.csv.gz
done

# Download Yellow Taxi Data (2020)
echo "Downloading Yellow Taxi 2020 data..."
for month in $(seq -f "%02g" 1 12); do
    wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2020-${month}.csv.gz
done

# Download Green Taxi Data (2019)
echo "Downloading Green Taxi 2019 data..."
for month in $(seq -f "%02g" 1 12); do
    wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-${month}.csv.gz
done

# Download Green Taxi Data (2020)
echo "Downloading Green Taxi 2020 data..."
for month in $(seq -f "%02g" 1 12); do
    wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2020-${month}.csv.gz
done

# Download Taxi Zone Lookup Table
echo "Downloading Taxi Zone Lookup..."
wget https://d37ci6vzurychx.cloudfront.net/misc/taxi+_zone_lookup.csv

echo "Download complete!"
echo "Files saved in: $(pwd)"

# Decompress files
echo "Decompressing files..."
gunzip *.csv.gz

echo "All data ready!"
```

**Run the download script**:

```bash
# Make script executable
chmod +x data/download_data.sh

# Run download
./data/download_data.sh
```

**Alternative**: Download manually from:
- Yellow Taxi: https://github.com/DataTalksClub/nyc-tlc-data/releases/tag/yellow
- Green Taxi: https://github.com/DataTalksClub/nyc-tlc-data/releases/tag/green
- Zones: https://d37ci6vzurychx.cloudfront.net/misc/taxi+_zone_lookup.csv

---

### STEP 7: Load Data into PostgreSQL

#### Create Data Ingestion Script

Create `data/ingest_data.py`:

```python
#!/usr/bin/env python
"""
Script to ingest NYC Taxi data into PostgreSQL
"""

import pandas as pd
import sqlalchemy
from sqlalchemy import create_engine
from time import time
import argparse
import os

def main(params):
    user = params.user
    password = params.password
    host = params.host
    port = params.port
    db = params.db
    table_name = params.table_name
    csv_file = params.csv_file

    # Create database engine
    engine = create_engine(f'postgresql://{user}:{password}@{host}:{port}/{db}')

    print(f"Loading data from {csv_file}...")
    
    # Read CSV in chunks to handle large files
    df_iter = pd.read_csv(csv_file, iterator=True, chunksize=100000)
    
    # Get first chunk to create table
    df = next(df_iter)
    
    # Convert datetime columns
    if 'tpep_pickup_datetime' in df.columns:
        df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
        df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)
    elif 'lpep_pickup_datetime' in df.columns:
        df.lpep_pickup_datetime = pd.to_datetime(df.lpep_pickup_datetime)
        df.lpep_dropoff_datetime = pd.to_datetime(df.lpep_dropoff_datetime)
    
    # Create table with first chunk
    df.head(0).to_sql(name=table_name, con=engine, if_exists='replace')
    
    # Insert first chunk
    df.to_sql(name=table_name, con=engine, if_exists='append')
    
    print(f"Inserted first chunk of {len(df)} rows")
    
    # Insert remaining chunks
    chunk_num = 1
    while True:
        try:
            t_start = time()
            df = next(df_iter)
            
            # Convert datetime columns
            if 'tpep_pickup_datetime' in df.columns:
                df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
                df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)
            elif 'lpep_pickup_datetime' in df.columns:
                df.lpep_pickup_datetime = pd.to_datetime(df.lpep_pickup_datetime)
                df.lpep_dropoff_datetime = pd.to_datetime(df.lpep_dropoff_datetime)
            
            df.to_sql(name=table_name, con=engine, if_exists='append')
            
            t_end = time()
            chunk_num += 1
            print(f'Inserted chunk {chunk_num}, took %.3f seconds' % (t_end - t_start))
            
        except StopIteration:
            print(f"Finished loading {table_name}")
            break

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Ingest CSV data to PostgreSQL')
    
    parser.add_argument('--user', default='root', help='username for postgres')
    parser.add_argument('--password', default='root', help='password for postgres')
    parser.add_argument('--host', default='localhost', help='host for postgres')
    parser.add_argument('--port', default='5432', help='port for postgres')
    parser.add_argument('--db', default='ny_taxi', help='database name')
    parser.add_argument('--table_name', required=True, help='name of the table')
    parser.add_argument('--csv_file', required=True, help='path to the csv file')
    
    args = parser.parse_args()
    
    main(args)
```

#### Install Required Python Libraries

```bash
# Activate virtual environment
cd /path/to/module-4
source .venv/bin/activate  # Linux/Mac
# or
.venv\Scripts\Activate.ps1  # Windows

# Install required libraries
uv pip install pandas sqlalchemy psycopg2-binary
```

#### Load Sample Data (Yellow Taxi Jan 2019)

```bash
# Load first month to test
python data/ingest_data.py \
    --user=root \
    --password=root \
    --host=localhost \
    --port=5432 \
    --db=ny_taxi \
    --table_name=yellow_taxi_trips \
    --csv_file=data/raw/yellow_tripdata_2019-01.csv
```

#### Load All Data (Optional - Full Dataset)

Create `data/load_all_data.sh`:

```bash
#!/bin/bash

# Load all yellow taxi data
for year in 2019 2020; do
    for month in {01..12}; do
        echo "Loading yellow_tripdata_${year}-${month}.csv..."
        python ingest_data.py \
            --table_name=yellow_taxi_trips \
            --csv_file=raw/yellow_tripdata_${year}-${month}.csv
    done
done

# Load all green taxi data
for year in 2019 2020; do
    for month in {01..12}; do
        echo "Loading green_tripdata_${year}-${month}.csv..."
        python ingest_data.py \
            --table_name=green_taxi_trips \
            --csv_file=raw/green_tripdata_${year}-${month}.csv
    done
done

echo "All data loaded!"
```

**Note**: Loading all data takes ~30-60 minutes. For learning purposes, loading 2-3 months is sufficient!

---

### STEP 8: Install dbt Core

```bash
# Make sure you're in virtual environment
cd /path/to/module-4
source .venv/bin/activate

# Install dbt-core and postgres adapter
uv pip install dbt-core dbt-postgres

# Verify installation
dbt --version
```

Expected output:
```
Core:
  - installed: 1.7.x
  - latest:    1.7.x - Up to date!

Plugins:
  - postgres: 1.7.x - Up to date!
```

---

### STEP 9: Initialize dbt Project

```bash
# Navigate to project directory
cd dbt_project

# Initialize dbt project
dbt init taxi_rides_ny

# Select database
# When prompted: Which database would you like to use?
# Enter: 1 (for postgres)

# Project structure created:
# taxi_rides_ny/
# ├── analyses/
# ├── macros/
# ├── models/
# ├── seeds/
# ├── snapshots/
# ├── tests/
# ├── dbt_project.yml
# └── README.md
```

---

### STEP 10: Configure dbt Profile

#### Create/Edit `~/.dbt/profiles.yml`

```bash
# Create .dbt directory if it doesn't exist
mkdir -p ~/.dbt

# Create or edit profiles.yml
nano ~/.dbt/profiles.yml  # or use your preferred editor
```

Add this configuration:

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
      keepalives_idle: 0
      connect_timeout: 10
      
    prod:
      type: postgres
      host: localhost
      user: root
      password: root
      port: 5432
      dbname: ny_taxi
      schema: dbt_prod
      threads: 4
      keepalives_idle: 0
      connect_timeout: 10
```

**Save the file**.

---

### STEP 11: Test dbt Connection

```bash
# Navigate to dbt project
cd taxi_rides_ny

# Test connection
dbt debug
```

Expected output:
```
Running with dbt=1.7.x
dbt version: 1.7.x
python version: 3.x.x
python path: /path/to/venv/bin/python
os info: macOS-xx.x.x-x86_64
Using profiles.yml file at /Users/username/.dbt/profiles.yml
Using dbt_project.yml file at /path/to/taxi_rides_ny/dbt_project.yml

Configuration:
  profiles.yml file [OK found and valid]
  dbt_project.yml file [OK found and valid]

Required dependencies:
 - git [OK found]

Connection:
  host: localhost
  port: 5432
  user: root
  database: ny_taxi
  schema: dbt_dev
  Connection test: [OK connection ok]

All checks passed!
```

---

### STEP 12: Create First dbt Model

#### Create Staging Model for Yellow Taxi

Create `models/staging/stg_yellow_tripdata.sql`:

```sql
{{ config(materialized='view') }}

select
    -- identifiers
    {{ dbt_utils.generate_surrogate_key(['vendorid', 'tpep_pickup_datetime']) }} as tripid,
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
    
    -- payment info
    cast(fare_amount as numeric) as fare_amount,
    cast(extra as numeric) as extra,
    cast(mta_tax as numeric) as mta_tax,
    cast(tip_amount as numeric) as tip_amount,
    cast(tolls_amount as numeric) as tolls_amount,
    cast(improvement_surcharge as numeric) as improvement_surcharge,
    cast(total_amount as numeric) as total_amount,
    cast(payment_type as integer) as payment_type
    
from {{ source('staging', 'yellow_taxi_trips') }}

-- limit to 2019-2020 data for learning
where tpep_pickup_datetime >= '2019-01-01' 
  and tpep_pickup_datetime < '2021-01-01'
```

#### Create Source Definition

Create `models/staging/schema.yml`:

```yaml
version: 2

sources:
  - name: staging
    database: ny_taxi
    schema: public
    tables:
      - name: yellow_taxi_trips
      - name: green_taxi_trips
```

---

### STEP 13: Run First dbt Model

```bash
# Run all models
dbt run

# Or run specific model
dbt run --select stg_yellow_tripdata
```

Expected output:
```
Running with dbt=1.7.x
Found 1 model, 0 tests, 0 snapshots, 0 analyses, 0 macros, 0 operations, 0 seed files, 1 source, 0 exposures, 0 metrics

Concurrency: 4 threads (target='dev')

1 of 1 START sql view model dbt_dev.stg_yellow_tripdata ................. [RUN]
1 of 1 OK created sql view model dbt_dev.stg_yellow_tripdata ............ [CREATE VIEW in 0.15s]

Finished running 1 view model in 0.45s.

Completed successfully

Done. PASS=1 WARN=0 ERROR=0 SKIP=0 TOTAL=1
```

---

### STEP 14: Verify Model Creation

#### Using pgcli:

```bash
pgcli -h localhost -p 5432 -u root -d ny_taxi
```

```sql
-- Check schema
\dn

-- Check tables/views in dbt_dev schema
\dt dbt_dev.*
\dv dbt_dev.*

-- Query the model
SELECT COUNT(*) FROM dbt_dev.stg_yellow_tripdata;

-- Sample data
SELECT * FROM dbt_dev.stg_yellow_tripdata LIMIT 10;
```

#### Using pgAdmin:

1. Navigate to: Servers → NY Taxi Local → Databases → ny_taxi → Schemas → dbt_dev → Views
2. Right-click `stg_yellow_tripdata` → View/Edit Data → All Rows

---

## Verification & Testing

### System Check Checklist:

- [ ] Docker Desktop running
- [ ] PostgreSQL container up (port 5432)
- [ ] pgAdmin accessible (http://localhost:8080)
- [ ] Database connection successful
- [ ] Sample data loaded
- [ ] dbt installed and version verified
- [ ] dbt connection test passed
- [ ] First model created and runs successfully
- [ ] Can query model in PostgreSQL

### Quick Test Commands:

```bash
# Check Docker containers
docker ps

# Check dbt
dbt --version
dbt debug

# Run models
dbt run

# Generate documentation
dbt docs generate
dbt docs serve  # Opens in browser
```

---

## Common Issues & Solutions

### Issue 1: Port 5432 Already in Use

**Problem**: PostgreSQL already running locally

**Solution**:
```bash
# Stop local PostgreSQL
sudo systemctl stop postgresql  # Linux
brew services stop postgresql   # macOS

# Or change port in docker-compose.yml
ports:
  - "5433:5432"  # Use 5433 instead
```

### Issue 2: Docker Permission Denied (Linux)

**Problem**: Need sudo for docker commands

**Solution**:
```bash
sudo usermod -aG docker $USER
newgrp docker
# Logout and login again
```

### Issue 3: dbt Connection Failed

**Problem**: Can't connect to database

**Solution**:
```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Test connection manually
psql -h localhost -p 5432 -U root -d ny_taxi

# Verify profiles.yml configuration
cat ~/.dbt/profiles.yml
```

### Issue 4: Out of Memory

**Problem**: Docker runs out of memory

**Solution**:
- Increase Docker memory in Docker Desktop settings (8GB recommended)
- Load data in smaller batches
- Reduce `threads` in profiles.yml

### Issue 5: Data Download Fails

**Problem**: wget not found or download fails

**Solution**:
```bash
# Install wget
# macOS:
brew install wget

# Ubuntu:
sudo apt-get install wget

# Or use curl instead:
curl -O [URL]
```

---

## Quick Reference Commands

### Docker Commands:
```bash
# Start services
cd docker && docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f postgres

# Restart services
docker-compose restart

# Remove everything (including data)
docker-compose down -v
```

### dbt Commands:
```bash
# Basic workflow
dbt run              # Run all models
dbt test             # Run all tests
dbt build            # Run and test everything

# Specific selections
dbt run --select stg_yellow_tripdata
dbt run --select staging.*
dbt run --select +my_model+  # Include upstream and downstream

# Documentation
dbt docs generate
dbt docs serve

# Debugging
dbt debug
dbt compile
dbt ls  # List all models
```

### PostgreSQL Commands:
```bash
# Connect with pgcli
pgcli -h localhost -p 5432 -u root -d ny_taxi

# Inside psql/pgcli:
\l                    # List databases
\dn                   # List schemas
\dt schema.*          # List tables in schema
\dv schema.*          # List views in schema
\d table_name         # Describe table
\q                    # Quit
```

---

## Project Directory Structure

Final structure after setup:

```
module-4/
├── .venv/                          # Python virtual environment
├── data/
│   ├── raw/                        # Downloaded CSV files
│   │   ├── yellow_tripdata_2019-01.csv
│   │   ├── green_tripdata_2019-01.csv
│   │   └── taxi+_zone_lookup.csv
│   ├── download_data.sh
│   ├── ingest_data.py
│   └── load_all_data.sh
├── docker/
│   └── docker-compose.yml
└── dbt_project/
    └── taxi_rides_ny/
        ├── analyses/
        ├── macros/
        ├── models/
        │   └── staging/
        │       ├── stg_yellow_tripdata.sql
        │       └── schema.yml
        ├── seeds/
        ├── snapshots/
        ├── tests/
        ├── dbt_project.yml
        └── README.md
```

---

## Next Steps

Now that your local setup is complete:

1. ✅ **Create more staging models** (green taxi, seeds)
2. ✅ **Build fact and dimension models**
3. ✅ **Add tests to ensure data quality**
4. ✅ **Generate and review documentation**
5. ✅ **Complete the homework assignments**

Proceed to **TASK 4** to solve the homework!

---

## Additional Resources

- **dbt Documentation**: https://docs.getdbt.com/
- **PostgreSQL Docs**: https://www.postgresql.org/docs/
- **DataTalks.Club Slack**: Join for community support
- **Course GitHub**: https://github.com/DataTalksClub/data-engineering-zoomcamp

---

**Setup Complete! 🎉**

You now have a fully functional local analytics engineering environment ready for Module 4 homework.

---

*Created for: Module-04 Analytics Engineering*  
*DataTalks.Club Data Engineering Zoomcamp 2026*
