import pandas as pd
from sqlalchemy import create_engine

engine = create_engine(
    "postgresql://root:root@localhost:5432/ny_taxi"
    )

# Load green taxi data
green_df = pd.read_parquet(
    "ny_taxi_postgres_data/raw/green_tripdata_2025-11.parquet"
    )
green_df.to_sql("green_tripdata", 
                engine, 
                if_exists="replace", 
                index=False)

# Load zones
zones_df = pd.read_csv(
    "ny_taxi_postgres_data/raw/taxi_zone_lookup.csv"
    )
zones_df.to_sql("taxi_zones",
                engine,
                if_exists="replace",
                index=False
                )

print("Data successfully loaded into PostgreSQL.")