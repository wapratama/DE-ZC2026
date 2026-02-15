-- FHV staging model
-- Location: models/staging/stg_fhv_tripdata.sql

{{
    config(
        materialized='view'
    )
}}

with source as (
    select * from {{ source('staging', 'fhv_tripdata') }}
),

renamed as (
    select
        -- identifiers
        dispatching_base_num,
        cast(pulocationid as integer) as pickup_location_id,
        cast(dolocationid as integer) as dropoff_location_id,
        
        -- timestamps
        cast(pickup_datetime as timestamp) as pickup_datetime,
        cast(dropoff_datetime as timestamp) as dropoff_datetime,
        
        -- other fields
        cast(sr_flag as integer) as sr_flag,
        affiliated_base_number
        
    from source
    where dispatching_base_num is not null
      and pickup_datetime >= '2019-01-01'
      and pickup_datetime < '2020-01-01'
)

select * from renamed