import json
import pandas as pd
from kafka import KafkaProducer
from time import time

# ── Config ──────────────────────────────────────────────
BOOTSTRAP_SERVER = 'localhost:9092'
TOPIC = 'green-trips'
DATA_URL = 'https://d37ci6vzurychx.cloudfront.net/trip-data/green_tripdata_2025-10.parquet'

COLUMNS = [
    'lpep_pickup_datetime',
    'lpep_dropoff_datetime',
    'PULocationID',
    'DOLocationID',
    'passenger_count',
    'trip_distance',
    'tip_amount',
    'total_amount',
]

# ── Serializer ───────────────────────────────────────────
def json_serializer(data):
    return json.dumps(data).encode('utf-8')

# ── Load data ────────────────────────────────────────────
print("Loading parquet file...")
df = pd.read_parquet(DATA_URL, columns=COLUMNS)

# Convert datetime columns to string (required for JSON + Flink later) and sort it by pickup time to simulate real-time data
df['lpep_pickup_datetime'] = df['lpep_pickup_datetime'].dt.strftime('%Y-%m-%d %H:%M:%S')
df['lpep_dropoff_datetime'] = df['lpep_dropoff_datetime'].dt.strftime('%Y-%m-%d %H:%M:%S')
df = df.sort_values('lpep_pickup_datetime').reset_index(drop=True)

# Fill NaN values to avoid JSON serialization errors
df = df.fillna(0)

print(f"Loaded {len(df)} rows. Connecting to Kafka...")

# ── Producer ─────────────────────────────────────────────
producer = KafkaProducer(
    bootstrap_servers=[BOOTSTRAP_SERVER],
    value_serializer=json_serializer
)

# ── Send ─────────────────────────────────────────────────
t0 = time()

for _, row in df.iterrows():
    producer.send(TOPIC, value=row.to_dict())

producer.flush()

t1 = time()
print(f'Sent {len(df)} records. Took {(t1 - t0):.2f} seconds')