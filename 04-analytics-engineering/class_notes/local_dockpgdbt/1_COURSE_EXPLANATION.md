# Module 4: Analytics Engineering - Complete Course Overview

## 📚 TASK 1: DETAILED COURSE EXPLANATION

---

## Course Overview

**Module Name**: Analytics Engineering  
**Course**: Data Engineering Zoomcamp by DataTalksClub  
**Cohort**: 2026  
**Duration**: 1 week (Week 4 of 9-week program)

### 🎯 Primary Goal

Transform raw data loaded in a Data Warehouse (DWH) into **Analytical Views** by developing a **dbt (data build tool) project**.

---

## What is Analytics Engineering?

### The Role Evolution

Analytics Engineering is a **bridge role** that emerged from the modern data stack evolution:

```
Traditional Setup:
┌─────────────────┐     ┌──────────────┐     ┌────────────────┐
│  Data Engineer  │ →→→ │   Raw Data   │ →→→ │  Data Analyst  │
└─────────────────┘     └──────────────┘     └────────────────┘
   (Builds infra)       (In warehouse)        (Analyzes data)
```

```
Modern Setup with Analytics Engineering:
┌─────────────────┐     ┌──────────────┐     ┌────────────────────┐     ┌────────────────┐
│  Data Engineer  │ →→→ │   Raw Data   │ →→→ │ Analytics Engineer │ →→→ │  Data Analyst  │
└─────────────────┘     └──────────────┘     └────────────────────┘     └────────────────┘
   (Builds infra)       (In warehouse)        (Transforms data)         (Consumes data)
                                              (Creates models)           (Creates insights)
                                              (Tests & Docs)
```

### Key Responsibilities of Analytics Engineers

1. **Data Modeling**: Transform raw data into well-structured analytical models
2. **Data Quality**: Implement tests to ensure data accuracy and consistency
3. **Documentation**: Create comprehensive documentation for data models
4. **Version Control**: Apply software engineering best practices (Git, CI/CD)
5. **Performance Optimization**: Ensure queries and transformations are efficient
6. **Collaboration**: Bridge gap between data engineers and analysts

---

## Core Concepts Covered in the Module

### 1. ETL vs ELT

**ETL (Extract, Transform, Load) - Traditional Approach**
```
Source Data → Transform (outside warehouse) → Load into Warehouse
```
- ✅ More stable and compliant
- ✅ Data validated before loading
- ❌ Higher computational costs
- ❌ Slower implementation
- ❌ Less flexible for ad-hoc analysis

**ELT (Extract, Load, Transform) - Modern Approach**
```
Source Data → Load into Warehouse → Transform (inside warehouse)
```
- ✅ Faster and more flexible
- ✅ Lower cost (leverage warehouse compute)
- ✅ Raw data always available
- ✅ Easier to iterate and experiment
- ❌ Requires proper data governance
- ❌ Need strong transformation layer (this is where dbt comes in!)

**Why ELT?**
- Modern cloud data warehouses (BigQuery, Snowflake, Redshift) are powerful
- Storage is cheap, compute is scalable
- Analysts need access to raw data for exploration
- Business requirements change frequently

### 2. Kimball's Dimensional Modeling

The module teaches the **Kimball methodology** for data warehouse design:

**Components:**

A. **Fact Tables**
- Contains quantitative data (metrics, measurements)
- Examples: sales transactions, taxi trips, website clicks
- Typically large tables with many rows
- Contains foreign keys to dimension tables

```sql
-- Example: fact_trips table
trip_id | pickup_datetime | dropoff_datetime | trip_distance | fare_amount | 
  PULocationID | DOLocationID | payment_type | vendor_id
```

B. **Dimension Tables**
- Contains descriptive attributes
- Examples: locations, dates, customers, products
- Relatively smaller tables
- Provides context to facts

```sql
-- Example: dim_zones table
locationid | borough | zone | service_zone
```

**Three-Layer Architecture:**

1. **Stage Area (Bronze Layer)**
   - Raw data as-is from sources
   - Minimal transformations
   - Example: `stg_yellow_tripdata`, `stg_green_tripdata`

2. **Processing Area (Silver Layer)**
   - Data cleaning and standardization
   - Business logic applied
   - Data quality checks
   - Example: intermediate models, cleaned staging

3. **Presentation Area (Gold Layer)**
   - Dimensional models (facts and dimensions)
   - Ready for consumption by BI tools
   - Optimized for analysis
   - Example: `fact_trips`, `dim_zones`

### 3. dbt (data build tool)

**What is dbt?**
- Open-source transformation tool
- Enables analysts to transform data using SQL
- Applies software engineering best practices to data transformations
- Version controlled, tested, documented

**dbt Core vs dbt Cloud**

| Feature | dbt Core | dbt Cloud |
|---------|----------|-----------|
| Type | CLI tool (free) | SaaS platform (paid) |
| Setup | Manual installation | Web-based, instant |
| IDE | Local text editor | Integrated IDE |
| Scheduling | External (Airflow, Cron) | Built-in scheduler |
| Documentation | Generate locally | Hosted automatically |
| Collaboration | Via Git | Built-in features |
| CI/CD | Manual setup | Integrated |
| Cost | Free | Tiered pricing |

**dbt Workflow:**
```
1. Write SQL models (SELECT statements)
2. Define how they should materialize (view, table, incremental)
3. Reference other models using {{ ref() }}
4. Test data quality
5. Generate documentation
6. Deploy to production
```

### 4. Data Modeling in dbt

**Model Structure:**
```
models/
├── staging/               # Bronze layer
│   ├── stg_yellow_tripdata.sql
│   └── stg_green_tripdata.sql
├── core/                  # Gold layer
│   ├── fact_trips.sql
│   └── dim_zones.sql
└── schema.yml            # Tests & documentation
```

**Materialization Strategies:**

1. **View** (default)
   - Creates a database view
   - Fast to build, slower to query
   - Good for models that don't need optimization

2. **Table**
   - Creates a physical table
   - Slower to build, faster to query
   - Good for frequently queried models

3. **Incremental**
   - Only processes new/changed data
   - Most efficient for large datasets
   - Requires unique key and logic for updates

4. **Ephemeral**
   - No database object created
   - Compiled as CTE in downstream models
   - Good for intermediate transformations

### 5. Jinja and Macros

**Jinja Templating:**
```sql
-- Use variables
WHERE pickup_datetime >= '{{ var("start_date") }}'

-- Conditionals
{% if target.name == 'prod' %}
  WHERE is_active = true
{% endif %}

-- Loops
{% for column in columns %}
  {{ column }},
{% endfor %}
```

**Macros (Reusable Functions):**
```sql
-- Define once
{% macro limit_data_in_dev(column_name, days_limit=3) %}
{% if target.name == 'dev' %}
  where {{ column_name }} >= current_date - interval '{{ days_limit }}' day
{% endif %}
{% endmacro %}

-- Use everywhere
select * from my_table
{{ limit_data_in_dev('created_at', 7) }}
```

### 6. Sources and Seeds

**Sources:**
- Raw tables in your warehouse
- Defined in `schema.yml`
- Referenced using `{{ source('schema', 'table') }}`
- Enables data freshness checks

**Seeds:**
- CSV files in your project
- Loaded using `dbt seed`
- Good for small reference data (lookup tables)
- Example: taxi zone lookup table

### 7. Testing

**Built-in Tests:**
- `unique`: Column values are unique
- `not_null`: No null values
- `accepted_values`: Values from predefined list
- `relationships`: Foreign key constraints

**Custom Tests:**
- SQL queries that return failing rows
- More complex business logic validation

```yaml
models:
  - name: fact_trips
    columns:
      - name: trip_id
        tests:
          - unique
          - not_null
      - name: payment_type
        tests:
          - accepted_values:
              values: [1, 2, 3, 4, 5]
```

### 8. Documentation

**Auto-generated Documentation:**
- Model lineage graphs (DAG visualization)
- Column descriptions
- Test results
- Source freshness
- Accessible via web interface

---

## Dataset Used in Module

### NYC Taxi Trip Data (2019-2020)

**Yellow Taxi Data:**
- Traditional NYC yellow cabs
- Trips in Manhattan primarily
- ~16-20 columns including pickup/dropoff times, locations, fares

**Green Taxi Data:**
- Boro taxis (outer boroughs)
- Trips outside Manhattan
- Similar schema to yellow taxi

**Taxi Zone Lookup:**
- 265 taxi zones in NYC
- Mapping of LocationID to Borough, Zone, Service Zone

**Data Volume:**
- Millions of trip records
- ~500MB-1GB per month of data
- Years 2019-2020 for learning purposes

**Note:** FHV (For-Hire Vehicle) data may be mentioned but is NOT used in the core dbt project for this module.

---

## Learning Path & Structure

### Module Videos/Sections:

1. **Introduction to Analytics Engineering**
   - Role definition
   - Modern data stack

2. **Data Modeling Concepts**
   - ETL vs ELT
   - Kimball dimensional modeling
   - Fact and dimension tables

3. **dbt Introduction**
   - What is dbt
   - dbt Core vs Cloud
   - Setup and configuration

4. **Hands-on: First dbt Models**
   - Creating staging models
   - Using sources
   - Model materialization

5. **Advanced dbt Features**
   - Macros and Jinja
   - Packages
   - Variables and configurations

6. **Seeds and References**
   - Loading CSV data
   - Referencing models
   - Building dependencies

7. **Fact and Dimension Models**
   - Building fact_trips
   - Creating dim_zones
   - Joining and transforming

8. **Testing dbt Models**
   - Built-in tests
   - Custom tests
   - Data quality validation

9. **Documentation**
   - Generating docs
   - Viewing lineage
   - Best practices

10. **Deployment**
    - CI/CD concepts
    - Production deployment
    - Scheduling transformations

---

## Skills You'll Develop

### Technical Skills:
1. ✅ SQL proficiency (advanced)
2. ✅ dbt development and best practices
3. ✅ Data modeling (Kimball methodology)
4. ✅ Version control with Git
5. ✅ Testing and validation
6. ✅ Documentation practices
7. ✅ Performance optimization

### Conceptual Skills:
1. ✅ Understanding ELT architecture
2. ✅ Dimensional modeling principles
3. ✅ Data quality concepts
4. ✅ Analytics engineering workflow
5. ✅ Software engineering for data

---

## Prerequisites

### Knowledge Prerequisites:
- SQL fundamentals (SELECT, JOIN, WHERE, GROUP BY)
- Basic understanding of databases
- Command line basics
- Git basics (helpful but not mandatory)

### Technical Prerequisites:

**Path 1: Local Setup** (No cost)
- Docker installed
- PostgreSQL
- Python & pip
- ~5GB free disk space

**Path 2: Cloud Setup** (GCP credits needed)
- Google Cloud Platform account
- BigQuery access
- ~$10-20 in credits (free tier available)

---

## Homework Focus Areas

The Module 4 homework emphasizes:

1. **Window Functions**: 
   - ROW_NUMBER(), RANK(), DENSE_RANK()
   - LAG(), LEAD()
   - Running totals and moving averages

2. **CTEs (Common Table Expressions)**:
   - WITH clauses
   - Complex multi-step transformations
   - Readable SQL structure

3. **dbt Modeling**:
   - Creating staging models
   - Building fact tables
   - Testing models
   - Using variables

4. **Data Analysis**:
   - Counting records
   - Aggregations
   - Joins and filtering
   - Performance considerations

---

## Why This Module Matters

### Industry Relevance:
- **dbt is industry standard** for data transformation
- **Analytics engineering is a growing field** (high demand)
- **Modern data stack knowledge** is essential
- **Portfolio project**: Real-world data modeling experience

### Career Impact:
- Adds valuable skill to resume
- Bridges data engineer and analyst roles
- Opens doors to analytics engineering positions
- Demonstrates software engineering maturity

---

## Community & Support

- **Slack Channel**: #course-data-engineering
- **GitHub**: Course materials and homework
- **Office Hours**: Weekly Q&A sessions
- **Peer Learning**: Active community of learners

---

## Summary

Module 4 transforms you from someone who can query data to someone who can **architect, transform, and maintain production data models**. You'll learn to:

1. Apply dimensional modeling principles
2. Use dbt for production-grade transformations
3. Implement data quality testing
4. Document data pipelines
5. Follow analytics engineering best practices

By the end, you'll have built a complete analytics layer on top of NYC taxi data, ready to power dashboards and analysis!

---

**Next Steps**: 
- Task 2: Compare Local vs Cloud setup
- Task 3: Detailed local setup guide
- Task 4: Solve homework using local setup

---

*Created for: Module-04 Analytics Engineering*  
*DataTalks.Club Data Engineering Zoomcamp 2026*
