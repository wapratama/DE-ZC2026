# Data Warehouse with BigQuery

Important resource & link to learn more about Google Bigquery.

## Bigquery
BigQuery is a fully managed, AI-ready data platform that helps you manage and analyze your data with built-in features like machine learning, search, geospatial analysis, and business intelligence. 

Table types
- Standard BigQuery tables: structured data stored in BigQuery storage.
- External tables: tables that reference data stored outside BigQuery.
- Views: logical tables that are created by using a SQL query.

Resources:
1. Overview: https://cloud.google.com/bigquery/docs/how-to or https://docs.cloud.google.com/bigquery/docs/introduction
2. Architecture: https://panoply.io/data-warehouse-guide/bigquery-architecture/
3. Storage overview: https://docs.cloud.google.com/bigquery/docs/storage_overview
4. Tables: https://docs.cloud.google.com/bigquery/docs/tables-intro
5. External Tables: https://docs.cloud.google.com/bigquery/docs/external-tables
6. Partitioned Table: https://cloud.google.com/bigquery/docs/partitioned-tables
7. Clustered Table: https://docs.cloud.google.com/bigquery/docs/clustered-tables
8. The quotas and system limits: https://docs.cloud.google.com/bigquery/quotas
9. Pricing: https://cloud.google.com/bigquery/pricing

## Direct Load Files to GCS
**NOTES FROM DE ZOOMCAMP REPO**: Quick hack to load files directly to GCS, without Airflow. Downloads csv files from https://nyc-tlc.s3.amazonaws.com/trip+data/ and uploads them to your Cloud Storage Account as parquet files.

Install pre-reqs (more info in web_to_gcs.py script). Run: 
```python 
python web_to_gcs.py
```
Resources: 
1. https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/03-data-warehouse/extras
2. https://docs.cloud.google.com/storage/docs/uploading-objects#storage-upload-object-python

## Machine Learning in Bigquery
1. Intro: https://docs.cloud.google.com/bigquery/docs/bqml-introduction
2. Create ML model using SQL: https://docs.cloud.google.com/bigquery/docs/create-machine-learning-model
5. Export model: https://docs.cloud.google.com/bigquery/docs/export-model-tutorial
5. GenAi in Bigquery: https://docs.cloud.google.com/bigquery/docs/generative-ai-overview

## Dremel
Dremel is Google’s internal data analysis and exploration system. It is designed for interactive (i.e. fast) analysis of read-only nested data. Its design builds on ideas from parallel database management systems as well as web search.

Resources:
1. Dremel: Interactive Analysis of Web-Scale Datasets: https://research.google/pubs/pub36632/
2. A Look at Dremel: http://www.goldsborough.me/distributed-systems/2019/05/18/21-09-00-a_look_at_dremel/


## Additional
Some inspiration: https://dev.to/pizofreude

Keep learning !!!