"""@bruin

name: ingestion.trips
connection: duckdb-default

materialization:
  type: table
  strategy: append

secrets:
  - key: duckdb-default
    inject_as: duckdb-default

columns:
  - name: vendorid
    type: INTEGER
  - name: tpep_pickup_datetime
    type: TIMESTAMP
  - name: tpep_dropoff_datetime
    type: TIMESTAMP
  - name: passenger_count
    type: DOUBLE
  - name: trip_distance
    type: DOUBLE
  - name: ratecodeid
    type: DOUBLE
  - name: store_and_fwd_flag
    type: VARCHAR
  - name: pulocationid
    type: INTEGER
  - name: dolocationid
    type: INTEGER
  - name: payment_type
    type: BIGINT
  - name: fare_amount
    type: DOUBLE
  - name: extra
    type: DOUBLE
  - name: mta_tax
    type: DOUBLE
  - name: tip_amount
    type: DOUBLE
  - name: tolls_amount
    type: DOUBLE
  - name: improvement_surcharge
    type: DOUBLE
  - name: total_amount
    type: DOUBLE
  - name: congestion_surcharge
    type: DOUBLE
  - name: airport_fee
    type: DOUBLE
  - name: cbd_congestion_fee
    type: DOUBLE
  - name: taxi_type
    type: VARCHAR
  - name: extracted_at
    type: TIMESTAMP

@bruin"""

import json
import os
import sys
from datetime import datetime
from io import BytesIO

import pandas as pd
import requests
from dateutil.relativedelta import relativedelta

# Force UTF-8 output — prevents UnicodeEncodeError on Windows terminals
sys.stdout.reconfigure(encoding="utf-8")


def materialize():
    """
    Fetch NYC Yellow Taxi trip data from the TLC public parquet endpoint.

    Bruin runtime context used:
    - BRUIN_START_DATE / BRUIN_END_DATE : date window for this run (YYYY-MM-DD)
    - BRUIN_VARS                        : JSON string with pipeline variables
                                          e.g. {"taxi_types": ["yellow", "green"]}

    Returns a pandas DataFrame for Bruin to materialize into DuckDB
    using the `append` strategy.
    """
    
    # ── 1. Parse date window ────────────────────────────────────────────────
    start_date_str = os.getenv("BRUIN_START_DATE", "2021-01-01")
    end_date_str   = os.getenv("BRUIN_END_DATE",   "2021-01-31")

    start_date = datetime.strptime(start_date_str[:10], "%Y-%m-%d").date()
    end_date   = datetime.strptime(end_date_str[:10],   "%Y-%m-%d").date()

    print(f"Date window: {start_date} to {end_date}")

    # ── 2. Parse taxi types from pipeline variables ─────────────────────────
    vars_json  = os.getenv("BRUIN_VARS", "{}")
    vars_dict  = json.loads(vars_json)
    taxi_types = vars_dict.get("taxi_types", ["yellow"])

    print(f"Taxi types: {taxi_types}")

    # ── 3. Build list of (taxi_type, year, month) to fetch ──────────────────
    url_params   = []
    current_date = start_date
    while current_date <= end_date:
        for taxi_type in taxi_types:
            url_params.append((taxi_type, current_date.year, current_date.month))
        current_date += relativedelta(months=1)

    # ── 4. Fetch and collect DataFrames ─────────────────────────────────────
    BASE_URL     = "https://d37ci6vzurychx.cloudfront.net/trip-data"
    extracted_at = datetime.utcnow()
    dfs          = []

    from pandas.api.types import is_datetime64tz_dtype

    for taxi_type, year, month in url_params:
        filename = f"{taxi_type}_tripdata_{year:04d}-{month:02d}.parquet"
        url      = f"{BASE_URL}/{filename}"

        print(f"Fetching {url}...")

        try:
            response = requests.get(url, timeout=60)
            response.raise_for_status()

            df = pd.read_parquet(BytesIO(response.content))

            # -------- Robust timezone removal (NEW) -------------------------
            # Convert any tz-aware datetime columns to UTC then make them naive,
            # so pyarrow on Windows won't require a system tzdata.
            for col in df.columns:
                try:
                    if is_datetime64tz_dtype(df[col].dtype):
                        df[col] = df[col].dt.tz_convert("UTC").dt.tz_localize(None)
                except Exception as e:
                    # fallback: attempt generic coercion then drop tz if present
                    try:
                        df[col] = pd.to_datetime(df[col])
                        if is_datetime64tz_dtype(df[col].dtype):
                            df[col] = df[col].dt.tz_convert("UTC").dt.tz_localize(None)
                    except Exception:
                        # warn but continue — better to return values than crash here
                        print(f"[WARN] could not normalize datetime column {col}: {e}")
            # ----------------------------------------------------------------

            # ── Add metadata columns ────────────────────────────────────────
            df["taxi_type"]    = taxi_type
            df["extracted_at"] = extracted_at

            # ── Normalize column names to snake_case ────────────────────────
            df.columns = [c.lower().strip() for c in df.columns]

            dfs.append(df)
            print(f"  [OK] Loaded {len(df):,} rows from {filename}")

        except requests.exceptions.HTTPError as e:
            print(f"  [SKIP] {filename} not available: {e}")
            continue
        except requests.exceptions.RequestException as e:
            print(f"  [FAILED] Could not fetch {url}: {e}")
            continue

    # ── 5. Return results ────────────────────────────────────────────────────
    if not dfs:
        print("[WARN] No data fetched. Returning empty DataFrame.")
        return pd.DataFrame()

    final_df = pd.concat(dfs, ignore_index=True)
    print(f"\nTotal rows ingested: {len(final_df):,}")

    return final_df
