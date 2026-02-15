-- Model: dim_zones
-- Location: models/core/dim_zones.sql

{{
    config(
        materialized='table'
    )
}}

select
    locationid,
    borough,
    zone,
    replace(service_zone, 'Boro', 'Green') as service_zone
from {{ ref('taxi_zone_lookup') }}