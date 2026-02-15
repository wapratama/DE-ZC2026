-- Green Taxi Trip Data Staging Model
-- Location: models/staging/stg_green_tripdata.sql

{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('staging', 'green_taxi_trips') }}
),

renamed as (
    select
        -- identifiers
        cast(vendorid as integer) as vendorid,
        cast(ratecodeid as integer) as ratecodeid,
        cast(pulocationid as integer) as pickup_locationid,
        cast(dolocationid as integer) as dropoff_locationid,
        
        -- timestamps
        cast(lpep_pickup_datetime as timestamp) as pickup_datetime,
        cast(lpep_dropoff_datetime as timestamp) as dropoff_datetime,
        
        -- trip info
        cast(passenger_count as integer) as passenger_count,
        cast(trip_distance as numeric) as trip_distance,
        cast(trip_type as integer) as trip_type,
        
        -- payment info
        cast(fare_amount as numeric) as fare_amount,
        cast(extra as numeric) as extra,
        cast(mta_tax as numeric) as mta_tax,
        cast(tip_amount as numeric) as tip_amount,
        cast(tolls_amount as numeric) as tolls_amount,
        cast(improvement_surcharge as numeric) as improvement_surcharge,
        cast(total_amount as numeric) as total_amount,
        cast(payment_type as integer) as payment_type,
        coalesce(cast(congestion_surcharge as numeric), 0) as congestion_surcharge,
        
        -- metadata
        'Green' as service_type
        
    from source
    where lpep_pickup_datetime >= '2019-01-01' 
      and lpep_pickup_datetime < '2021-01-01'
)

select * from renamed