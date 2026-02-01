# Install Kestra

1. Docker Compose Configuration
Edit docker-compose.yaml from Module 01 to have 4 containers on services (pgdatabase, pgadmin, kestra, and kestra_postgres). Run in your terminal
    ```bash
    docker compose up -d
    ```
2. Set Up User. Run Kestra on `localhost:8080`. Login using username & password you specified on YAML file

# Explore Kestra Course
## Kestra Concept
Flow Properties (The details in Documentation inside Kestra)
- Tasks
    - Inputs
    - Expression
    - Variables
    - Render Expressions Recursively
    - Outputs
- Plugin Defaults
- Trigger
- Concurrency
- Execution: There are some View you can check like Gantt, Logs, and Topology.

Code: `01_hello_world.yaml`

Workflow has number of tasks which can be defined by properties and pass data between them using Outputs

## Orchestrate Python Code
- Python Task Types
- Docker Task Runners
- Process Task Runners
- Kestra Python Package

Code: `02_python.yaml`

## Local DB: Load Taxi Data to Postgres

### Build First Data Pipeline
Tasks: Extract -> Transform -> Load -> Execute using SQL Query
Code: `03_getting_started_data_pipeline.yaml`

### Load Data into Postgres with ETL
Code: `04_postgres_taxi.yaml`

### Scheduling and Backfills
Code: `05_postgres_taxi_scheduled.yaml`

## ELT Pipelines in Kestra: Google Cloud Platform

### ETL vs ELT
- ETL (Extract, Transform, Load): data is extracted from the source, transformed into the desired format, and then loaded into the final destination
- ELT (Extract, Load, Transform): the transformation step is deferred until after the data has been loaded into the destination

### Kestra & GCP 
Code: 
- Setup Google Cloud Platform (GCP): `06_gcp_kv.yaml`
- Create GCP Resources (bucket and BigQuery): `07_gcp_setup.yaml`
- Workflow:
    - Load Taxi Data to BigQuery: `08_gcp_taxi.yaml`
    - Schedule and Backfill Full Dataset: `09_gcp_taxi_scheduled.yaml`

## Using AI for Data Engineering in Kestra
Code comparison of Retrieval With vs Without Context: 
- Without Context: `10_chat_without_rag.yaml`
- With Context: `11_chat_with_rag.yaml`

# Closing
Complete course guidance for Modul 2:
https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/02-workflow-orchestration 

# Additional
Actually, my disk is full for this Module, so I run these :

```bash
docker system prune -a --volumes # remove ALL Docker data (Image, Containers, Build Cache)
docker volume prune -a # remove all unused Local Volumes
```

Verify Disk is freed with run:
```bash
docker system df
```

**Thanks and keep learning !!!**