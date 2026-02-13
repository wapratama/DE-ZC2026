-- ============================================================================
-- Module 4 Homework - SQL Queries (2026 Cohort)
-- DataTalks.Club Data Engineering Zoomcamp
-- ============================================================================

-- Prerequisites: 
-- 1. dbt models built with: dbt build --target prod
-- 2. Connected to ny_taxi database
-- 3. Set search path: SET search_path TO dbt_prod;

-- ============================================================================
-- QUESTION 3: Count Records in fct_monthly_zone_revenue
-- ============================================================================

SELECT COUNT(*) as total_records
FROM dbt_prod.fct_monthly_zone_revenue;

-- Expected: ~14,120 (varies by data loaded)

-- Detailed breakdown
SELECT 
    revenue_year,
    service_type,
    COUNT(*) as record_count,
    SUM(total_monthly_trips) as total_trips,
    ROUND(SUM(revenue_monthly_total_amount)::numeric, 2) as total_revenue
FROM dbt_prod.fct_monthly_zone_revenue
GROUP BY revenue_year, service_type
ORDER BY revenue_year, service_type;

-- ============================================================================
-- QUESTION 4: Best Performing Zone for Green Taxis (2020)
-- ============================================================================

SELECT 
    zone,
    borough,
    SUM(revenue_monthly_total_amount) as total_revenue_2020,
    SUM(total_monthly_trips) as total_trips,
    ROUND(AVG(revenue_monthly_total_amount)::numeric, 2) as avg_monthly_revenue
FROM dbt_prod.fct_monthly_zone_revenue
WHERE service_type = 'Green'
  AND revenue_year = 2020
GROUP BY zone, borough
ORDER BY total_revenue_2020 DESC
LIMIT 10;

-- Expected Answer: East Harlem North

-- Verify the top zone
SELECT 
    zone,
    borough,
    ROUND(SUM(revenue_monthly_total_amount)::numeric, 2) as total_revenue
FROM dbt_prod.fct_monthly_zone_revenue
WHERE service_type = 'Green'
  AND revenue_year = 2020
GROUP BY zone, borough
ORDER BY total_revenue DESC
LIMIT 1;

-- ============================================================================
-- QUESTION 5: Green Taxi Trip Counts (October 2019)
-- ============================================================================

SELECT 
    revenue_month,
    TO_CHAR(revenue_month, 'Month YYYY') as month_name,
    SUM(total_monthly_trips) as total_trips_october_2019,
    COUNT(DISTINCT pickup_zone) as unique_zones,
    ROUND(SUM(revenue_monthly_total_amount)::numeric, 2) as total_revenue
FROM dbt_prod.fct_monthly_zone_revenue
WHERE service_type = 'Green'
  AND revenue_year = 2019
  AND revenue_month_num = 10
GROUP BY revenue_month;

-- Expected Answer: 384,624

-- Compare with other months in 2019
SELECT 
    revenue_month_num,
    TO_CHAR(revenue_month, 'Month YYYY') as month_name,
    SUM(total_monthly_trips) as total_trips,
    ROUND(AVG(total_monthly_trips)::numeric, 0) as avg_trips_per_zone
FROM dbt_prod.fct_monthly_zone_revenue
WHERE service_type = 'Green'
  AND revenue_year = 2019
GROUP BY revenue_month_num, revenue_month
ORDER BY revenue_month_num;

-- ============================================================================
-- QUESTION 6: FHV Staging Model Record Count
-- ============================================================================

SELECT COUNT(*) as fhv_record_count
FROM dbt_prod.stg_fhv_tripdata;

-- Expected Answer: 43,244,693

-- Detailed FHV statistics
SELECT 
    COUNT(*) as total_records,
    COUNT(DISTINCT dispatching_base_num) as unique_bases,
    COUNT(DISTINCT affiliated_base_number) as unique_affiliated_bases,
    MIN(pickup_datetime) as earliest_pickup,
    MAX(pickup_datetime) as latest_pickup,
    COUNT(DISTINCT pickup_datetime::date) as distinct_days
FROM dbt_prod.stg_fhv_tripdata;

-- Monthly breakdown
SELECT 
    DATE_TRUNC('month', pickup_datetime) as month,
    TO_CHAR(pickup_datetime, 'Month YYYY') as month_name,
    COUNT(*) as monthly_count,
    COUNT(DISTINCT dispatching_base_num) as unique_bases
FROM dbt_prod.stg_fhv_tripdata
GROUP BY DATE_TRUNC('month', pickup_datetime), TO_CHAR(pickup_datetime, 'Month YYYY')
ORDER BY month;

-- Compare with raw data (before filtering)
SELECT 
    COUNT(*) as total_raw_records,
    COUNT(*) FILTER (WHERE dispatching_base_num IS NOT NULL) as records_with_base,
    COUNT(*) FILTER (WHERE dispatching_base_num IS NULL) as records_without_base,
    ROUND(
        (COUNT(*) FILTER (WHERE dispatching_base_num IS NOT NULL)::numeric / COUNT(*) * 100),
        2
    ) as pct_with_base
FROM public.fhv_tripdata
WHERE pickup_datetime >= '2019-01-01' 
  AND pickup_datetime < '2020-01-01';

-- ============================================================================
-- BONUS QUERIES - Additional Analysis
-- ============================================================================

-- All models record counts
SELECT 
    'stg_green_tripdata' as model_name,
    COUNT(*) as records 
FROM dbt_prod.stg_green_tripdata
UNION ALL
SELECT 
    'stg_yellow_tripdata' as model_name,
    COUNT(*) as records 
FROM dbt_prod.stg_yellow_tripdata
UNION ALL
SELECT 
    'stg_fhv_tripdata' as model_name,
    COUNT(*) as records 
FROM dbt_prod.stg_fhv_tripdata
UNION ALL
SELECT 
    'fct_trips' as model_name,
    COUNT(*) as records 
FROM dbt_prod.fct_trips
UNION ALL
SELECT 
    'dim_zones' as model_name,
    COUNT(*) as records 
FROM dbt_prod.dim_zones
UNION ALL
SELECT 
    'fct_monthly_zone_revenue' as model_name,
    COUNT(*) as records 
FROM dbt_prod.fct_monthly_zone_revenue;

-- Service type breakdown in fct_trips
SELECT 
    service_type,
    COUNT(*) as trip_count,
    ROUND(AVG(total_amount)::numeric, 2) as avg_fare,
    ROUND(AVG(trip_distance)::numeric, 2) as avg_distance,
    MIN(pickup_datetime) as earliest_trip,
    MAX(pickup_datetime) as latest_trip
FROM dbt_prod.fct_trips
GROUP BY service_type;

-- Top 10 zones by total revenue (all service types, all years)
SELECT 
    zone,
    borough,
    service_type,
    SUM(total_monthly_trips) as total_trips,
    ROUND(SUM(revenue_monthly_total_amount)::numeric, 2) as total_revenue,
    ROUND(AVG(avg_monthly_trip_distance)::numeric, 2) as avg_distance
FROM dbt_prod.fct_monthly_zone_revenue
GROUP BY zone, borough, service_type
ORDER BY total_revenue DESC
LIMIT 10;

-- Revenue trends by month
SELECT 
    revenue_month,
    service_type,
    SUM(total_monthly_trips) as trips,
    ROUND(SUM(revenue_monthly_total_amount)::numeric, 2) as revenue
FROM dbt_prod.fct_monthly_zone_revenue
GROUP BY revenue_month, service_type
ORDER BY revenue_month, service_type;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check that prod schema exists and has tables
SELECT 
    schemaname, 
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'dbt_prod'
ORDER BY tablename;

-- Check for any failed tests
-- (Run this after: dbt test --target prod)
-- Check dbt logs or run: dbt test --select fct_trips --target prod

-- ============================================================================
-- END OF HOMEWORK QUERIES
-- ============================================================================
