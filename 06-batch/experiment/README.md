# PySpark with uv + Docker in VSCode
### DE Zoomcamp 2026 — Module 6 | No Local Spark/Java Install Required

> **The idea:** `uv` manages your Python packages (including PySpark), Docker provides the Java runtime Spark needs — so you never touch your host machine's system dependencies.

---

## 📋 Prerequisites

Install these before starting:

| Tool | Purpose | Install |
|------|---------|---------|
| **Docker Desktop** | Runs the containerized environment | https://www.docker.com/products/docker-desktop |
| **uv** | Fast Python package & project manager | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| **VSCode** | Editor | https://code.visualstudio.com |
| **VSCode Extensions** | Docker, Python, Jupyter | Install from Extensions panel |

Verify everything works:
```bash
docker --version       # Docker version 27.x.x
uv --version           # uv 0.5.x
code --version         # optional check
```

---

## 🗂️ Final Project Structure

Here's what you'll end up with — build it step by step below:

```
experiment/
│
├── .python-version            # pins Python version for uv
├── pyproject.toml             # uv project config + dependencies
├── uv.lock                    # auto-generated lockfile (commit this)
│
├── Dockerfile                 # Python + Java + uv inside container
├── docker-compose.yml         # orchestrates the container
├── .env                       # environment variables (not committed)
├── .dockerignore              # keeps image lean
│
├── data/                      # downloaded parquet + CSV files
│   ├── yellow_tripdata_2025-11.parquet
│   └── taxi_zone_lookup.csv
│
├── output/                    # Spark writes repartitioned files here
│
└── src/
    └── homework_06.py         # your homework solution script
```
**Note**: You can change your main folder name from `experiment` to whatever you want

---

## STEP 1 — Initialize the uv Project

Open your terminal (any location you want your project):

```bash
# Create and enter the project folder
uv init experiment
cd experiment
```

`uv init` creates: `pyproject.toml`, `main.py` (delete it), `README.md`, and `.python-version`.

```bash
# Pin to Python 3.11 (compatible with PySpark 3.3.x)
uv python pin 3.11

# Create the src directory and remove the boilerplate main.py
mkdir -p src data output
rm -f main.py hello.py
```

Check what was created:
```bash
cat .python-version
# 3.11
```

---

## STEP 2 — Add Dependencies with uv

```bash
# Add PySpark and supporting libraries
uv add pyspark pandas pyarrow jupyter ipykernel
```

This will:
- Create a virtual environment at `.venv/`
- Generate/update `uv.lock`
- Install all packages lightning-fast

Verify the lockfile was created:
```bash
ls -la
# You should see: pyproject.toml  uv.lock  .python-version  .venv/
```

Your `pyproject.toml` should now look like this example:

```toml
[project]
name = "experiment"
version = "0.1.0"
description = "DE Zoomcamp 2026 - Module 6 Batch Processing"
requires-python = ">=3.11"
dependencies = [
    "ipykernel>=7.2.0",
    "jupyter>=1.1.1",
    "pandas>=3.0.1",
    "pyarrow>=23.0.1",
    "pyspark>=4.1.1",
]

```

---

## STEP 3 — Create the Dockerfile

> **Why a Dockerfile?** PySpark requires Java. Your machine doesn't have Java (and we don't want to install it). The Docker image provides Java + your uv-managed Python environment, all isolated.

Create `Dockerfile` in the project root:

```dockerfile
# Dockerfile
FROM python:3.11-slim

# ── System dependencies: Java (required by Spark) ────────────────────────────
RUN apt-get update && apt-get install -y \
    default-jdk \
    curl \
    wget \
    procps \
    && rm -rf /var/lib/apt/lists/*

# ── Set JAVA_HOME so PySpark can find it ─────────────────────────────────────
ENV JAVA_HOME=/usr/lib/jvm/default-java
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# ── Install uv inside the container ──────────────────────────────────────────
RUN pip install uv

# ── Set working directory ─────────────────────────────────────────────────────
WORKDIR /app

# ── Copy dependency files first (layer caching — faster rebuilds) ─────────────
COPY pyproject.toml uv.lock ./

# ── Install Python dependencies using uv (reads uv.lock for exact versions) ──
RUN uv sync --frozen

# ── Copy the rest of the project ─────────────────────────────────────────────
COPY . .

# ── Make uv's venv the default Python ────────────────────────────────────────
ENV PATH="/app/.venv/bin:${PATH}"
ENV VIRTUAL_ENV="/app/.venv"

# ── Spark environment variables ───────────────────────────────────────────────
ENV PYSPARK_PYTHON=/app/.venv/bin/python
ENV PYSPARK_DRIVER_PYTHON=/app/.venv/bin/python

# Default command: open a bash shell
CMD ["/bin/bash"]
```

---

## STEP 4 — Create the Docker Compose File

Create `docker-compose.yml` in the project root.

This is an example, for container name here is `de_zoomcamp_spark`.

```yaml
# docker-compose.yml
version: "3.8"

services:
  spark:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: de_zoomcamp_spark
    
    # ── Port mappings ──────────────────────────────────────────────────────────
    ports:
      - "4040:4040"   # Spark UI (jobs, stages, storage, executors)
      - "8888:8888"   # Jupyter Notebook (if you use it)
    
    # ── Mount local folders into the container ────────────────────────────────
    volumes:
      - ./src:/app/src           # your Python scripts
      - ./data:/app/data         # parquet + CSV data files
      - ./output:/app/output     # Spark writes output here
    
    # ── Environment variables ─────────────────────────────────────────────────
    environment:
      - PYSPARK_PYTHON=/app/.venv/bin/python
      - PYSPARK_DRIVER_PYTHON=/app/.venv/bin/python
      - JAVA_HOME=/usr/lib/jvm/default-java
    
    # ── Resource limits (adjust to your machine) ──────────────────────────────
    deploy:
      resources:
        limits:
          memory: 4g        # Give Spark at least 2–4 GB RAM
    
    # ── Keep the container alive ──────────────────────────────────────────────
    stdin_open: true
    tty: true
    
    # ── Working directory inside the container ────────────────────────────────
    working_dir: /app
```

---

## STEP 5 — Create .dockerignore

Keeps the Docker build context lean (don't copy `.venv`, cache, or output into the image):

```
# .dockerignore
.venv/
__pycache__/
*.pyc
*.pyo
.pytest_cache/
.ruff_cache/
output/
data/
.git/
.gitignore
*.egg-info/
dist/
build/
```

---

## STEP 6 — Create .env (Optional but Good Practice)

```bash
# .env
SPARK_DRIVER_MEMORY=2g
COMPOSE_PROJECT_NAME=de_zoomcamp_m6
```

> ⚠️ Add `.env` to your `.gitignore` if you plan to push to GitHub.

---

## STEP 7 — Download the Data

Run this **from your host machine** (the data will be available inside the container via the volume mount):

```bash
# From the project root (example: experiment/)
wget -P data/ https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-11.parquet
wget -P data/ https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv

# Verify
ls -lh data/
# yellow_tripdata_2025-11.parquet   ~100MB
# taxi_zone_lookup.csv              ~12KB
```

> **Windows users:** use `curl` instead:
> ```powershell
> curl -o data/yellow_tripdata_2025-11.parquet https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-11.parquet
> curl -o data/taxi_zone_lookup.csv https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv
> ```

---

## STEP 8 — Build the Docker Image

```bash
# From project root — this may take 3–5 minutes the first time
docker compose build

# You'll see:
# [+] Building ...
#  => FROM python:3.11-slim
#  => apt-get install default-jdk ...
#  => pip install uv
#  => uv sync --frozen
#  => DONE
```

To verify the image was created:
```bash
docker images | grep de-zoomcamp
```

---

## STEP 9 — Run the Container

### Option A: Run the script directly (one-shot, if any)

```bash
docker compose run --rm spark python src/script.py
```

- `--rm` removes the container automatically after it exits (clean)
- You'll see all the results in your terminal

### Option B: Start an interactive shell (for exploring)

```bash
docker compose up -d       # start container in background
docker exec -it de_zoomcamp_m6 bash
```

Inside the container you can:
```bash
# Run the homework
python src/homework_06.py

# Or open PySpark REPL interactively
pyspark

# Or run Jupyter (then open http://localhost:8888)
jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root
```

### Option C: Run from VSCode terminal (attach to container)

1. Open VSCode Command Palette: `Ctrl+Shift+P` → `Dev Containers: Attach to Running Container`
2. Select `de_zoomcamp_spark`
3. Open the `/app` folder
4. Use the VSCode integrated terminal — you're now inside the container
5. Run: `python src/script.py`

---

## STEP 10 — Explore the Data and Finish the Homework

Run Jupyter (then open http://localhost:8888) and create your notebook. For example, check on my [`homework_06.ipynb`](../06-batch/experiment/src/homework_06.ipynb).

---

## STEP 11 — Watch Spark UI While It Runs

While the script is running, open your browser:

```
http://localhost:4040
```

You'll see:
- **Jobs tab** — each `count()`, `write()`, `show()` is a job
- **Stages tab** — how each job is broken into stages
- **Storage tab** — cached DataFrames
- **Executors tab** — memory and CPU usage

> The UI is only available **while the Spark session is active**. It closes when the script ends.

---

## STEP 12 — Verify the Output

After the partition script runs, you can also check the output from your host machine:

```bash
# See the 4 parquet files created by Q2
ls -lh output/yellow_2025_11_4parts/

# Output:
# part-00000-....parquet    ~25MB
# part-00001-....parquet    ~25MB
# part-00002-....parquet    ~25MB
# part-00003-....parquet    ~25MB
# _SUCCESS
```

---

## STEP 13 — Clean Up 
**WARNING: Please do it carefully!**

### Stop the running container
```bash
docker compose down
```

### Remove the container AND the built image
```bash
docker compose down --rmi all
```

### Remove output data (optional)
```bash
rm -rf output/yellow_2025_11_4parts/
```

### Remove the downloaded parquet data (large file)
```bash
rm data/yellow_tripdata_2025-11.parquet
```

### Full nuclear clean (removes everything Docker-related)
```bash
# WARNING: this clears ALL stopped containers, unused images, and build cache
docker system prune -af
```
or


```bash
docker system prune -a --volumes # remove ALL Docker data (Image, Containers, Build Cache)
docker volume prune -a # remove all unused Local Volumes
```

It is generally safe to use in development and testing environments but requires caution in production.
Verify Disk is freed with run:
```bash
docker system df
```

### Remove the uv virtual environment (if you want a fresh start)
```bash
rm -rf .venv/
uv sync    # re-creates it from scratch
```



---

## Quick Reference — All Commands

```bash
# ── Project Init ───────────────────────────────────────────────
uv init experiment
cd experiment
uv python pin 3.11
mkdir -p src data output
uv add pyspark pandas pyarrow jupyter ipykernel

# ── Download Data ──────────────────────────────────────────────
wget -P data/ https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-11.parquet
wget -P data/ https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv

# ── Build ──────────────────────────────────────────────────────
docker compose build

# ── Run Homework (one-shot) ────────────────────────────────────
docker compose run --rm spark python src/script.py

# ── Interactive Shell ──────────────────────────────────────────
docker compose up -d
docker exec -it de_zoomcamp_spark bash

# ── Spark UI (in browser while script runs) ────────────────────
# http://localhost:4040

# ── Stop ───────────────────────────────────────────────────────
docker compose down

# ── or Full Clean ─────────────────────────────────────────────────
docker compose down --rmi all
docker system prune -af
```

---

## Troubleshooting

### "Cannot find JAVA_HOME"
```bash
# Rebuild the image — Java setup may have been cached incorrectly
docker compose build --no-cache
```

### "Port 4040 already in use"
```bash
# Find and kill what's using it
lsof -i :4040
kill -9 <PID>
# Or change the port in docker-compose.yml: "4041:4040"
```

### "Out of memory" / Spark crashes
```bash
# Increase memory limit in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 6g   # try 4g or 6g

# Also set in the SparkSession:
.config("spark.driver.memory", "3g")
```

### "No such file or directory: data/yellow_tripdata..."
```bash
# Make sure wget downloaded to the right place
ls data/
# If empty, re-run the wget command from the project root
```

### Parquet file unreadable / schema error
```bash
# The 2025 data may use different column names. Check with:
docker compose run --rm spark python -c "
from pyspark.sql import SparkSession
spark = SparkSession.builder.master('local[*]').getOrCreate()
df = spark.read.parquet('/app/data/yellow_tripdata_2025-11.parquet')
df.printSchema()
df.show(2)
"
```

### uv.lock conflict after adding packages
```bash
uv lock --upgrade   # regenerate the lockfile
docker compose build  # rebuild image with updated deps
```

---

## Why This Setup is Great

| Concern | How it's handled |
|---------|-----------------|
| Java not on host machine | Docker image provides it |
| Reproducible Python deps | `uv.lock` pins exact versions |
| Fast package installs | uv is 10–100× faster than pip |
| Data not inside image | Volume mounts keep image small |
| Clean environment | `--rm` flag auto-removes containers |
| Port conflicts | Only 4040 + 8888 exposed |
| Different OS (Windows/Mac/Linux) | Docker normalizes the environment |

---

*This document is created with Claude AI using some references from main DE Zoomcamp repo and some adjustment from me*