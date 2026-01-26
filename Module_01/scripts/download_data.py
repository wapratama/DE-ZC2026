from pathlib import Path
import requests

DATA_DIR = Path("ny_taxi_postgres_data/raw")
DATA_DIR.mkdir(parents=True, exist_ok=True)

files = {
    "green_tripdata_2025-11.parquet":
    "https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-11.parquet",
    "taxi_zone_lookup.csv":
    "https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv",
    }

for filename, url in files.items():
    path = DATA_DIR / filename
    if path.exists():
        print(f"{filename} already exists, skipping.")
        continue

    print(f"Downloading {filename}...")
    response = requests.get(url, timeout=60)
    response.raise_for_status()
    path.write_bytes(response.content)

print("Download complete.") 