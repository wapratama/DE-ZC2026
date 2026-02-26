/* @bruin
name: staging.trips
type: duckdb.sql

depends:
  - ingestion.trips
  - ingestion.payment_lookup

materialization:
  type: table
  strategy: time_interval
  incremental_key: pickup_datetime
  time_granularity: timestamp

columns:
  - name: pickup_datetime
    type: timestamp
    primary_key: true
    checks:
      - name: not_null
  - name: dropoff_datetime
    type: timestamp
  - name: pickup_location_id
    type: integer
    checks:
      - name: not_null
  - name: dropoff_location_id
    type: integer
  - name: fare_amount
    type: float
  - name: taxi_type
    type: string
  - name: payment_type_name
    type: string

custom_checks:
  - name: row_count_greater_than_zero
    query: |
      SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
      FROM staging.trips
    value: 1
@bruin */

SELECT
    t.tpep_pickup_datetime    AS pickup_datetime,
    t.tpep_dropoff_datetime   AS dropoff_datetime,
    t.pulocationid            AS pickup_location_id,
    t.dolocationid            AS dropoff_location_id,
    t.fare_amount,
    t.taxi_type,
    p.payment_type_name
FROM ingestion.trips t
LEFT JOIN ingestion.payment_lookup p
    ON t.payment_type = p.payment_type_id
WHERE t.tpep_pickup_datetime >= '{{ start_datetime }}'
  AND t.tpep_pickup_datetime < '{{ end_datetime }}'
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY t.tpep_pickup_datetime, t.tpep_dropoff_datetime,
                 t.pulocationid, t.dolocationid, t.fare_amount
    ORDER BY t.tpep_pickup_datetime
) = 1
