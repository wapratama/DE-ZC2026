-- Model: fct_trips
-- Location: models/core/fct_trips.sql

{{
    config(
        materialized='table'
    )
}}

with green_trips as (
    select * from {{ ref('stg_green_tripdata') }}
),

yellow_trips as (
    select * from {{ ref('stg_yellow_tripdata') }}
),

trips_unioned as (
    select * from green_trips
    union all
    select * from yellow_trips
)

select
    -- metadata
    service_type,
    
    -- identifiers
    vendorid,
    ratecodeid,
    pickup_locationid,
    dropoff_locationid,
    
    -- timestamps
    pickup_datetime,
    dropoff_datetime,
    
    -- trip info
    passenger_count,
    trip_distance,
    trip_type,
    
    -- payment info
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,
    payment_type,
    congestion_surcharge
    
from trips_unioned