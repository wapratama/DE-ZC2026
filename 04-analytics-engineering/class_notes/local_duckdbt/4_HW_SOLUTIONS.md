**Module 4: Analytics Engineering**
#  4: solve the Module-04 homework using the Local Setup

Because the homework contains a mix of conceptual multiple-choice (Q1–Q2) and data queries (Q3–Q6), I’ll give you:

* Concrete dbt model files you can paste into your local dbt project (DuckDB local target).
* `profiles.yml` example that provides a `prod` target mapped to a local DuckDB file so `--target prod` works exactly as homework requests.
* `schema.yml` tests.
* Exact commands to run (`dbt build --target prod`) and the SQL queries you run afterwards to obtain each homework answer.
* Instructions for downloading the required data (Green/Yellow 2019–2020 + FHV 2019 parquet), and where to put them in your local project.

I will **not** guess or fabricate numeric answers for Q3–Q6 — you must run the pipeline with the real data to obtain those numbers. I will however give you the precise steps and files so you can produce the correct numbers quickly and reproducibly.

---

## Quick plan / assumptions

1. You already followed Task 3 and created a local dbt project (DuckDB) under e.g. `module_04_local/module_04_local_dbt`.
2. Parquet files will be placed under `module_04_local/data/raw/` (one folder for all input files).
3. We will update `profiles.yml` so `prod` target writes to `data/duckdb_prod.db`.
4. Models we add:

   * staging: `stg_yellow_tripdata`, `stg_green_tripdata`, `stg_fhv_tripdata`
   * intermediate: `int_trips_unioned`
   * facts: `fct_trips`, `fct_monthly_zone_revenue`
   * dim: `dim_zones` (simple pass-through from taxi zone lookup if needed)
5. After `dbt build --target prod` you will query the produced models to answer homework Q3–Q6.

---

## A — Download & place the data (where to put files)

Place these files in project `data/raw/` (path relative to your dbt project's folder):

```
module_04_local/
  data/
    raw/
      yellow_tripdata_2019-01.parquet
      ...
      yellow_tripdata_2020-12.parquet
      green_tripdata_2019-01.parquet
      ...
      green_tripdata_2020-12.parquet
      fhv_tripdata_2019-01.parquet  (from FHV release)
      taxi_zone_lookup.csv
```

**How to download** (example, run from `module_04_local/data/raw`):

```bash
# Yellow & Green (example pattern — replace with the official URLs you used earlier)
wget https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2019-01.parquet
# repeat for 2019-01 .. 2020-12 for yellow and green, or use the full file set you have

# FHV (2019) release (example link; follow the project's release page for exact file URLs)
# If multiple files exist, download all 2019 FHV files to this folder
# taxi zone lookup
wget https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
```

> Tip: If files are many, you can use `gsutil`/`wget` loops or download only the months you need for homework (but the homework requests 2019–2020 for green and yellow).

---

## B — `profiles.yml` (so `--target prod` works locally)

Put a `profiles.yml` in the same folder as your `dbt_project.yml` (or set `DBT_PROFILES_DIR` to that folder). Example file:

```yaml
module_04_local_dbt:
  outputs:
    dev:
      type: duckdb
      path: "../data/duckdb_dev.db"
      threads: 1
      extensions: []
    prod:
      type: duckdb
      path: "../data/duckdb_prod.db"
      threads: 1
      extensions: []
  target: dev
```

* This provides both `dev` and `prod`. Homework requires building `--target prod`. `prod` points to `../data/duckdb_prod.db` so it is isolated from dev.
* Set `DBT_PROFILES_DIR` before running dbt, if needed:

  ```bash
  export DBT_PROFILES_DIR=$(pwd)   # run from directory containing profiles.yml
  ```

---

## C — Files to add to your dbt project

Create the following files under `module_04_local/module_04_local_dbt/models/` (adjust paths if your project is elsewhere). I give the SQL + schema YAML content. Copy/paste to files exactly.

### 1) `models/staging/stg_yellow_tripdata.sql`

(Adjust column names to match your parquet schema if different)

```sql
-- models/staging/stg_yellow_tripdata.sql
{{ config(materialized='table') }}

SELECT
  vendorid as vendor_id,
  tpep_pickup_datetime,
  tpep_dropoff_datetime,
  passenger_count,
  trip_distance,
  PULocationID as pickup_location_id,
  DOLocationID as dropoff_location_id,
  fare_amount,
  extra,
  mta_tax,
  tip_amount,
  tolls_amount,
  improvement_surcharge,
  total_amount,
  payment_type
FROM read_parquet('../data/raw/yellow_tripdata_2019-01.parquet') -- for single-file testing
UNION ALL
SELECT * FROM read_parquet('../data/raw/yellow_tripdata_2019-02.parquet')
-- add UNION ALL for all months OR use a wildcard file read depending on DuckDB version
;
```

**Note:** If you have many files, replace the explicit reads with a dynamic approach; DuckDB supports `read_parquet('../data/raw/yellow_tripdata_*.parquet')` in many versions — try that first.

### 2) `models/staging/stg_green_tripdata.sql`

```sql
-- models/staging/stg_green_tripdata.sql
{{ config(materialized='table') }}

SELECT
  vendorid as vendor_id,
  lpep_pickup_datetime as pickup_datetime,
  lpep_dropoff_datetime as dropoff_datetime,
  passenger_count,
  trip_distance,
  PULocationID as pickup_location_id,
  DOLocationID as dropoff_location_id,
  fare_amount,
  extra,
  mta_tax,
  tip_amount,
  tolls_amount,
  improvement_surcharge,
  total_amount,
  payment_type
FROM read_parquet('../data/raw/green_tripdata_2019-01.parquet')
UNION ALL
SELECT * FROM read_parquet('../data/raw/green_tripdata_2019-02.parquet')
-- add other months similarly or use a wildcard
;
```

> If you use wildcard `read_parquet('../data/raw/green_tripdata_*.parquet')`, the union lines are unnecessary.

### 3) `models/intermediate/int_trips_unioned.sql`

```sql
-- models/intermediate/int_trips_unioned.sql
{{ config(materialized='table') }}

SELECT
  'yellow' as taxi_type,
  vendor_id,
  tpep_pickup_datetime as pickup_datetime,
  tpep_dropoff_datetime as dropoff_datetime,
  passenger_count,
  trip_distance,
  pickup_location_id,
  dropoff_location_id,
  total_amount,
  payment_type
FROM {{ ref('stg_yellow_tripdata') }}

UNION ALL

SELECT
  'green' as taxi_type,
  vendor_id,
  pickup_datetime,
  dropoff_datetime,
  passenger_count,
  trip_distance,
  pickup_location_id,
  dropoff_location_id,
  total_amount,
  payment_type
FROM {{ ref('stg_green_tripdata') }}
;
```

### 4) `models/dim/dim_zones.sql` (simple pass-through using the taxi_zone_lookup CSV)

```sql
-- models/dim/dim_zones.sql
{{ config(materialized='table') }}

SELECT
  CAST(location_id AS INTEGER) as location_id,
  borough,
  zone
FROM read_csv_auto('../data/raw/taxi_zone_lookup.csv')
;
```

### 5) `models/fct/fct_monthly_zone_revenue.sql`

```sql
-- models/fct/fct_monthly_zone_revenue.sql
{{ config(materialized='table') }}

SELECT
  taxi_type,
  DATE_TRUNC('month', pickup_datetime) AS revenue_month,
  pickup_location_id,
  z.zone as pickup_zone,
  COUNT(*) AS total_monthly_trips,
  SUM(COALESCE(total_amount,0)) AS revenue_monthly_total_amount
FROM {{ ref('int_trips_unioned') }} t
LEFT JOIN {{ ref('dim_zones') }} z
  ON CAST(t.pickup_location_id AS INTEGER) = z.location_id
GROUP BY taxi_type, revenue_month, pickup_location_id, z.zone
ORDER BY revenue_month DESC, revenue_monthly_total_amount DESC
;
```

### 6) `models/fct/fct_trips.sql` (optional fact table)

```sql
-- models/fct/fct_trips.sql
{{ config(materialized='table') }}

SELECT
  taxi_type,
  DATE(pickup_datetime) AS day,
  COUNT(*) AS trips,
  SUM(COALESCE(total_amount, 0)) AS revenue
FROM {{ ref('int_trips_unioned') }}
GROUP BY taxi_type, day
;
```

### 7) `models/staging/stg_fhv_tripdata.sql` (for Question 6)

```sql
-- models/staging/stg_fhv_tripdata.sql
{{ config(materialized='table') }}

SELECT
  dispatching_base_num,
  CAST(PUlocationID AS INTEGER) as pickup_location_id,
  CAST(DOlocationID AS INTEGER) as dropoff_location_id,
  pickup_datetime,
  dropoff_datetime,
  passenger_count,
  trip_distance,
  fare_amount,
  total_amount
FROM read_parquet('../data/raw/fhv_tripdata_2019-01.parquet')  -- or wildcard for all FHV 2019 files
WHERE dispatching_base_num IS NOT NULL
;
```

> Adjust parquet filenames if your FHV files are named differently. If FHV has many monthly files, use wildcard `read_parquet('../data/raw/fhv_*2019*.parquet')`.

---

## D — `schema.yml` for tests (models folder)

Create (or append) `models/schema.yml`:

```yaml
version: 2

sources: []

models:
  - name: stg_yellow_tripdata
    tests:
      - dbt_utils.not_empty
  - name: stg_green_tripdata
    tests:
      - dbt_utils.not_empty

  - name: int_trips_unioned
    description: "Union of green + yellow trips"
    tests:
      - dbt_utils.not_empty

  - name: dim_zones
    tests:
      - dbt_utils.not_empty

  - name: fct_monthly_zone_revenue
    tests:
      - dbt_utils.not_empty

  - name: stg_fhv_tripdata
    description: "Staged FHV 2019"
    tests:
      - dbt_utils.not_empty
```

**Note:** `dbt_utils.not_empty` requires `dbt-utils` package. If you prefer not to add packages, you can use builtin `not_null` tests on specific columns. To add `dbt-utils` add to `packages.yml`:

`packages.yml` (project root)

```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: 0.9.7  # set to a compatible version with your dbt
```

Run `uv run dbt deps` to install packages.

---

## E — Add `dbt_project.yml` configuration (materializations defaults)

In your `dbt_project.yml` ensure you have sensible default materializations:

```yaml
name: 'module_04_local_dbt'
version: '1.0'
config-version: 2

profile: 'module_04_local_dbt'

model-paths: ["models"]
target-path: "target"
analysis-paths: ["analysis"]
macro-paths: ["macros"]
test-paths: ["tests"]
data-paths: ["data"]

models:
  module_04_local_dbt:
    +materialized: view
    staging:
      +materialized: table
    intermediate:
      +materialized: table
    dim:
      +materialized: table
    fct:
      +materialized: table
```

This sets staging/intermediate/dim/fct to become tables by default; change as needed.

---

## F — Run dbt (build production target)

From your dbt project directory (where `dbt_project.yml` and `profiles.yml` are), ensure `DBT_PROFILES_DIR` points there, then:

```bash
# make sure profile dir set:
export DBT_PROFILES_DIR=$(pwd)

# install deps if you added packages
uv run dbt deps

# build everything in prod target (as homework requires)
uv run dbt build --target prod
```

`dbt build` runs models + tests + snapshots in the correct order. With the `profiles.yml` above, `--target prod` will write into `data/duckdb_prod.db`.

---

## G — How to answer each homework question

I’ll go question by question and show exact SQL/commands to run to obtain the result.

### **Question 1 — dbt lineage & execution**

> If you run `dbt run --select int_trips_unioned`, what models will be built?

**Answer (explain):**
dbt builds the selected model and all **upstream dependencies** required to compile it. So running `dbt run --select int_trips_unioned` will build `stg_green_tripdata`, `stg_yellow_tripdata`, and `int_trips_unioned`. It will **not** build arbitrary downstream models.
So the correct choice is:

* `stg_green_tripdata`, `stg_yellow_tripdata`, and `int_trips_unioned` (upstream dependencies)

No need to run anything to prove this, but you can observe it:

```bash
uv run dbt run --models int_trips_unioned --target prod --profiles-dir $(pwd)
```

dbt will print the run order — verify that the staging models are built first.

---

### **Question 2 — dbt tests with accepted_values**

Given a generic test `accepted_values` listing allowed values and a new value `6` appears in source. What happens when you run:

```bash
uv run dbt test --select fct_trips --target prod
```

**Answer (explain):**
dbt test executes all configured tests against the current model data. If a test asserts `accepted_values` and source data contains an unexpected value (6), the test **fails** and `dbt test` returns a non-zero exit code. So the correct option is:

* `dbt will fail the test, returning a non-zero exit code`

You can simulate this by inserting a row or modifying a staging table to include `payment_type = 6` and running `dbt test`. The test result will show failures.

---

### **Question 3 — Count of records in `fct_monthly_zone_revenue`**

After `dbt build --target prod`, run:

```sql
SELECT COUNT(*) AS cnt
FROM fct_monthly_zone_revenue;
```

In DuckDB via Python CLI:

```bash
uv run python - <<'PY'
import duckdb
con = duckdb.connect('data/duckdb_prod.db')   # path matches profiles prod path
print(con.execute("SELECT COUNT(*) FROM fct_monthly_zone_revenue").fetchall())
PY
```

The output will give the exact count. Compare that result to the 4 choices in homework and pick the matching one.

---

### **Question 4 — Best Performing Zone for Green Taxis (2020)**

Run this SQL to find highest total revenue for Green taxi trips in 2020:

```sql
SELECT pickup_zone, SUM(revenue_monthly_total_amount) AS total_rev
FROM fct_monthly_zone_revenue
WHERE taxi_type = 'green' AND EXTRACT(year FROM revenue_month) = 2020
GROUP BY pickup_zone
ORDER BY total_rev DESC
LIMIT 1;
```

In DuckDB (Python):

```bash
uv run python - <<'PY'
import duckdb
con = duckdb.connect('data/duckdb_prod.db')
print(con.execute("""
SELECT pickup_zone, SUM(revenue_monthly_total_amount) AS total_rev
FROM fct_monthly_zone_revenue
WHERE taxi_type = 'green' AND EXTRACT(year FROM revenue_month) = 2020
GROUP BY pickup_zone
ORDER BY total_rev DESC
LIMIT 1;
""").fetchall())
PY
```

That will return the zone name — choose the matching multiple choice option.

---

### **Question 5 — Green Taxi Trip Counts (October 2019)**

Run:

```sql
SELECT SUM(total_monthly_trips) AS trips_oct_2019
FROM fct_monthly_zone_revenue
WHERE taxi_type = 'green'
  AND revenue_month = DATE '2019-10-01';
```

Or:

```sql
SELECT SUM(total_monthly_trips) AS trips_oct_2019
FROM fct_monthly_zone_revenue
WHERE taxi_type = 'green'
  AND EXTRACT(year FROM revenue_month) = 2019
  AND EXTRACT(month FROM revenue_month) = 10;
```

Then compare the numeric result to the options and pick the correct one.

---

### **Question 6 — Build a staging model for FHV data and return count**

1. Download FHV 2019 parquet(s) into `data/raw/` (as earlier instructions).
2. Place the provided `models/staging/stg_fhv_tripdata.sql` into your models folder (we provided above).
3. Run:

```bash
uv run dbt run --models stg_fhv_tripdata --target prod
```

4. Then query the count:

```bash
uv run python - <<'PY'
import duckdb
con = duckdb.connect('data/duckdb_prod.db')
print(con.execute("SELECT COUNT(*) FROM stg_fhv_tripdata").fetchall())
PY
```

The returned number will correspond to one of the multiple-choice answers in Q6 — pick the matching one.

---

## H — Practical run order summary

1. Ensure profile/environment:

```bash
cd module_04_local/module_04_local_dbt
export DBT_PROFILES_DIR=$(pwd)
uv run dbt deps        # if you have packages
uv run dbt debug --target prod
```

2. Build production models:

```bash
uv run dbt build --target prod
```

3. (If you want to run a single model)

```bash
uv run dbt run --models int_trips_unioned --target prod
```

4. Run tests:

```bash
uv run dbt test --target prod
```

5. Query results via duckdb (as shown above) to answer Q3–Q6.

---

## I — Notes & troubleshooting

* **Wildcards for Parquet**: DuckDB supports `read_parquet('../data/raw/yellow_tripdata_*.parquet')`. If your DuckDB version supports it, prefer that instead of many `UNION ALL` lines.
* **Column name mismatches**: Parquet from yellow vs green have different datetime column names (tpep_ vs lpep_) — staging SQL normalizes them. Double-check actual column names in your files and adapt select column names accordingly.
* **Large files & memory**: If you have many months, DuckDB will handle them but ensure Codespace has enough disk and memory; if not, test on a smaller subset first.
* **dbt_utils**: If you used `dbt_utils.not_empty`, add `packages.yml` and run `dbt deps`.
* **Schema.yml tests**: you can add more tests (unique keys, accepted_values) if desired.

---

## J — Submission & reproducibility

* When you finished and have the counts, fill the homework form with the selected options.
* Commit your dbt project (only model SQL, config, docstrings, tests). **Do not** commit `data/` or the DuckDB `.db` file. Ensure `.gitignore` contains `data/` and `data/duckdb_prod.db`.
* Optionally, generate docs and snapshot them:

  ```bash
  uv run dbt docs generate
  uv run dbt docs serve
  ```

  Save `target/catalog.json` and `target/manifest.json` if you want proof of runs.

---

## K — Final checks you can run to prove everything worked

1. Confirm prod database file exists:

```bash
ls -lh ../data/duckdb_prod.db
```

2. Show models built:

```bash
uv run dbt ls --target prod
```

3. Show run results:

```bash
cat target/run_results.json
```

4. Query the top revenue zone for green 2020 (example again):

```bash
uv run python - <<'PY'
import duckdb
con = duckdb.connect('data/duckdb_prod.db')
print(con.execute("""
SELECT pickup_zone, SUM(revenue_monthly_total_amount) AS total_rev
FROM fct_monthly_zone_revenue
WHERE taxi_type = 'green' AND EXTRACT(year FROM revenue_month) = 2020
GROUP BY pickup_zone
ORDER BY total_rev DESC
LIMIT 5;
""").fetchdf())
PY
```

---

## Closing notes

* I provided reproducible model code (staging → intermediate → mart) and tests so your `dbt build --target prod` produces the `fct_monthly_zone_revenue`, `fct_trips`, `dim_zones` and `stg_fhv_tripdata` models needed to answer the homework.
* Run the commands above with the real parquet files you downloaded to compute the numeric answers for Q3–Q6. I did **not** invent numeric answers — run the pipeline to get your actual numbers (this also demonstrates you can produce the results reproducibly).

---
