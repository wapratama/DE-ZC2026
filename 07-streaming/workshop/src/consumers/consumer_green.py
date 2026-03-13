import json
from kafka import KafkaConsumer

# ── Config ───────────────────────────────────────────────
BOOTSTRAP_SERVER = 'localhost:9092'
TOPIC = 'green-trips'

# ── Consumer ─────────────────────────────────────────────
consumer = KafkaConsumer(
    TOPIC,
    bootstrap_servers=[BOOTSTRAP_SERVER],
    auto_offset_reset='earliest',      # Read from beginning
    group_id='green-trips-counter',
    value_deserializer=lambda x: json.loads(x.decode('utf-8')),
    consumer_timeout_ms=10000          # Stop after 10s of no new messages
)

# ── Count ────────────────────────────────────────────────
total = 0
long_trips = 0

for message in consumer:
    ride = message.value
    total += 1
    if ride.get('trip_distance', 0) > 5.0:
        long_trips += 1

consumer.close()

print(f"Total trips read  : {total}")
print(f"Trips > 5.0 km    : {long_trips}")