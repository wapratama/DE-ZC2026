**Module 4: Analytics Engineering**
# Task 3: full, concrete, production-grade Local Setup (dbt + DuckDB) 

For this step-by-step, you can run from **VS Code**. I’ll assume you’re working inside your project workspace (not `$HOME`) and that you want an isolated `uv` environment per module. I’ll include exact commands (use `uv` as we agreed), minimal config files you can copy/paste, and example dbt models/tests that read Parquet and transform it. Follow steps in order.

---

## Overview (what we’ll build)

* Create a new folder `module_04_local` inside your workspace.
* Create a `uv` Python virtual environment and install `dbt-core`, `dbt-duckdb`, and `duckdb`.
* Initialize a dbt project (`dbt init`), create `profiles.yml` to point to a local DuckDB database file.
* Prepare Parquet input files in `data/raw/`.
* Create `models/` with:

  * `sources.yml` (source definitions)
  * staging model that reads Parquet into DuckDB table
  * mart model(s) (aggregations) with tests
* Run `dbt run`, `dbt test`, `dbt docs generate` and `dbt docs serve`
* Clean up & tips for commits and reproducibility

---

# Step-by-Step (copy + paste)

### 0 — Start in the right place

Open VS Code → Terminal (bash) and ensure you’re in your repo workspace:

```bash
# from repo root
mkdir -p module_04_local
cd module_04_local
pwd   # should be /workspaces/<repo>/module_04_local
```

---

### 1 — Create `uv` virtual environment and install packages

```bash
# initialize uv project (if not already)
uv init

# create virtual environment
uv venv

# install dbt and duckdb
uv add dbt-core dbt-duckdb duckdb
# Alternatively, to pin versions, e.g.:
# uv add "dbt-core==1.6.1" "dbt-duckdb==1.6.1" "duckdb==1.11.1"
```

> Notes:
>
> * `uv add` will update `pyproject.toml` and install packages into `.venv`.
> * You can run dbt commands with `uv run dbt ...` (no manual `activate` needed). If you prefer manual activation: `source .venv/bin/activate`.

Verify:

```bash
uv run dbt --version
```

You should see dbt + duckdb adapter version output.

---

### 2 — Project layout (create folders & copy data)

Create directories:

```bash
mkdir -p data/raw models macros analysis logs
```

Place your Parquet files under `data/raw/`. Example:

* `data/raw/yellow_tripdata_2024-01.parquet`
* `data/raw/green_tripdata_2024-01.parquet`

(If you don’t yet have files, copy small sample parquet for testing.)

Check:

```bash
ls -lh data/raw
```

---

### 3 — Initialize dbt project

Run:

```bash
uv run dbt init module_04_local_dbt
```

When prompted:

* Project name: `module_04_local_dbt` (or accept default)
* Choose `duckdb` adapter when asked (if prompt doesn't, we'll edit `profiles.yml` manually)

This creates `module_04_local_dbt/` with default structure. Move into it:

```bash
cd module_04_local_dbt
```

Project structure now:

```
module_04_local/
└─ module_04_local_dbt/
   ├─ models/
   ├─ dbt_project.yml
   └─ ...
```

---

### 4 — Create dbt profile for DuckDB

dbt looks for `~/.dbt/profiles.yml` by default. Create a local `profiles.yml` in `~/.dbt` or you can set `DBT_PROFILES_DIR` to point to project folder. I recommend project-local `profiles.yml` and export `DBT_PROFILES_DIR` for reproducibility.

Create `profiles.yml` in your project root (module_04_local/module_04_local_dbt/profiles.yml):

```yaml
module_04_local_dbt:
  outputs:
    dev:
      type: duckdb
      path: "../data/duckdb.db"   # relative path to store the database file
      threads: 1
      extensions: []
  target: dev
```

Export environment variable so dbt picks it up:

```bash
export DBT_PROFILES_DIR=$(pwd)   # now dbt reads profiles.yml in this folder
```

Verify:

```bash
uv run dbt debug
```

You should see `All checks passed!` (or connection success). If you get errors, ensure `path` is writable.

---

### 5 — Add a `sources.yml` to declare raw data

In `module_04_local_dbt/models/` create `src_trips.yml`:

```yaml
version: 2

sources:
  - name: nyc_raw
    tables:
      - name: yellow_raw
        description: "Raw yellow taxi parquet (Jan 2024 sample)"
      - name: green_raw
        description: "Raw green taxi parquet (Jan 2024 sample)"
```

(We’ll materialize these source tables from Parquet in model SQL.)

---

### 6 — Create staging models that load Parquet into DuckDB

Create `models/stg_yellow.sql`:

```sql
-- models/stg_yellow.sql
{{ config(materialized='table') }}

SELECT *
FROM read_parquet('../data/raw/yellow_tripdata_2024-01.parquet')
```

And `models/stg_green.sql` similarly:

```sql
-- models/stg_green.sql
{{ config(materialized='table') }}

SELECT *
FROM read_parquet('../data/raw/green_tripdata_2024-01.parquet')
```

Notes:

* `read_parquet()` is a DuckDB function that can read parquet files. The dbt-duckdb adapter will execute this SQL against the DuckDB connection file.
* Use relative paths as shown; DuckDB runs from project directory; adjust path if using different working dir.

Add `models/schema.yml` to declare tests for the staging models:

```yaml
version: 2

models:
  - name: stg_yellow
    description: "Staging yellow taxi"
    columns:
      - name: tpep_pickup_datetime
        tests:
          - not_null
      - name: tpep_dropoff_datetime
        tests:
          - not_null
  - name: stg_green
    description: "Staging green taxi"
    columns:
      - name: pickup_datetime
        tests:
          - not_null
```

> Important: column names must match real parquet schema. Adjust names if different.

---

### 7 — Create marts / analytics models

Example aggregated model: `models/mart/daily_trips.sql`

```sql
-- models/mart/daily_trips.sql
{{ config(materialized='table') }}

SELECT
  DATE(tpep_pickup_datetime) AS day,
  COUNT(*) AS trips,
  AVG(fare_amount) AS avg_fare
FROM {{ ref('stg_yellow') }}
GROUP BY day
ORDER BY day
```

Add tests in `models/mart/schema.yml`:

```yaml
version: 2

models:
  - name: daily_trips
    description: "Daily aggregated trips"
    columns:
      - name: day
        tests:
          - not_null
      - name: trips
        tests:
          - not_null
```

---

### 8 — Run dbt models & tests

From project directory where `dbt_project.yml` lives and `DBT_PROFILES_DIR` is set:

```bash
# compile & run models
uv run dbt run

# run tests
uv run dbt test
```

Expected behavior:

* `stg_yellow` and `stg_green` tables get created in `../data/duckdb.db` (DuckDB file)
* `mart.daily_trips` gets created
* Tests run, showing pass/fail

If any test fails, inspect logs in `target/` or query `duckdb` to debug.

---

### 9 — Generate docs and view lineage

```bash
uv run dbt docs generate
uv run dbt docs serve
```

This opens a local server (default port 8080) showing model docs and DAG.

---

### 10 — Example queries (validate outputs)

You can use DuckDB CLI or Python to query results, or use dbt `run-operation` or `dbt test` outputs. Using `duckdb` CLI:

```bash
uv run python - <<'PY'
import duckdb
con = duckdb.connect('data/duckdb.db')
print(con.execute("SELECT count(*) FROM daily_trips").fetchall())
print(con.execute("SELECT * FROM daily_trips LIMIT 5").fetchall())
PY
```

---

### 11 — Version control & `.gitignore`

Create `.gitignore` in `module_04_local` root (or repo root):

```gitignore
# Python
.venv/
__pycache__/
*.pyc

# dbt
target/
dbt_modules/

# DuckDB file and data
data/duckdb.db
data/*.parquet
data/raw/
```

**Important**: Do NOT commit `data/duckdb.db` or raw data. Commit `models/`, `dbt_project.yml`, `profiles.yml` (if you want reproducibility you can keep a sample profile for others but don't include secrets).

Commit everything safe:

```bash
git add .
git commit -m "Module 04 local dbt project: initial models"
```

---

### 12 — Reproducibility notes

To reproduce on another machine:

1. Copy project repo (excluding data).
2. Place sample parquet files in `data/raw/`.
3. Run:

   ```bash
   cd module_04_local/module_04_local_dbt
   uv venv
   uv add dbt-core dbt-duckdb duckdb
   export DBT_PROFILES_DIR=$(pwd)
   uv run dbt deps  # if using packages
   uv run dbt run
   uv run dbt test
   ```

---

## Extra: Incremental model pattern (for large tables)

If your data grows and you want to practice incremental builds, use:

`models/mart/incremental_trips.sql`:

```sql
{{ config(materialized='incremental', unique_key='trip_id') }}

WITH new_rows AS (
  SELECT *
  FROM read_parquet('../data/raw/yellow_tripdata_2024-01.parquet')
  WHERE DATE(tpep_pickup_datetime) > (SELECT COALESCE(MAX(day), '1970-01-01') FROM {{ this }})
)
SELECT
  *, DATE(tpep_pickup_datetime) AS day
FROM new_rows
```

Then run:

```bash
uv run dbt run --models mart.incremental_trips
```

Make sure `trip_id` or a unique identifier exists. Adjust logic to match schema.

---

## Troubleshooting common issues

* **`read_parquet` fails with path not found**: check working directory and relative path. You can use absolute path `'/workspaces/.../module_04_local/data/raw/file.parquet'`.
* **dbt debug fails**: confirm `DBT_PROFILES_DIR` and `profiles.yml` content and permissions.
* **Tests fail**: open `target/run_results.json` or `target/test_results.json` for details.
* **Permission denied writing `data/duckdb.db`**: ensure folder writable.

---

## Security & data hygiene reminders

* Don’t commit raw parquet or the DuckDB file.
* `.gitignore` must exclude `data/` and `.venv/`
* Keep any real credentials out of project — local workflow uses local files only.

---

## Quick checklist (what to run in order)

1. `cd module_04_local`
2. `uv init` (if not already)
3. `uv venv`
4. `uv add dbt-core dbt-duckdb duckdb`
5. Place parquet files in `data/raw/`
6. `cd module_04_local_dbt`
7. create `profiles.yml` and `export DBT_PROFILES_DIR=$(pwd)`
8. `uv run dbt debug`
9. `uv run dbt run`
10. `uv run dbt test`
11. `uv run dbt docs generate && uv run dbt docs serve`

---

## What we just set up (recap)

* Local dbt project using DuckDB as the warehouse
* Staging models read Parquet with `read_parquet()` (materialized as tables in DuckDB)
* Mart model(s) aggregate and test data quality
* Docs & lineage available locally

This fully satisfies the **Local Setup** path for Module 04 and gives you everything needed to do the homework locally.

---
