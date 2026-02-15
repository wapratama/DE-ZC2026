-- Model: fct_monthly_zone_revenue
-- Location: models/core/fct_monthly_zone_revenue.sql

{{
    config(
        materialized='table'
    )
}}

with trips as (
    select * from {{ ref('fct_trips') }}
),

dim_zones as (
    select * from {{ ref('dim_zones') }}
)

select
    -- time dimensions
    date_trunc('month', pickup_datetime) as revenue_month,
    extract(year from pickup_datetime) as revenue_year,
    extract(month from pickup_datetime) as revenue_month_num,
    
    -- location dimensions
    trips.pickup_locationid as pickup_zone,
    zones.borough,
    zones.zone,
    
    -- service type
    trips.service_type,
    
    -- aggregated metrics
    count(*) as total_monthly_trips,
    sum(trips.fare_amount) as revenue_monthly_fare,
    sum(trips.extra) as revenue_monthly_extra,
    sum(trips.mta_tax) as revenue_monthly_mta_tax,
    sum(trips.tip_amount) as revenue_monthly_tip_amount,
    sum(trips.tolls_amount) as revenue_monthly_tolls_amount,
    sum(trips.improvement_surcharge) as revenue_monthly_improvement_surcharge,
    sum(trips.total_amount) as revenue_monthly_total_amount,
    sum(trips.congestion_surcharge) as revenue_monthly_congestion_surcharge,
    
    -- averages
    avg(trips.passenger_count) as avg_monthly_passenger_count,
    avg(trips.trip_distance) as avg_monthly_trip_distance

from trips
inner join dim_zones as zones
    on trips.pickup_locationid = zones.locationid
    
group by 
    revenue_month,
    revenue_year,
    revenue_month_num,
    trips.pickup_locationid,
    zones.borough,
    zones.zone,
    trips.service_type