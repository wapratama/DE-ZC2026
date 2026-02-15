#!/usr/bin/env python
"""
NYC Taxi Data Ingestion Script
DataTalks.Club Data Engineering Zoomcamp - Module 4

This script ingests NYC Taxi CSV data into PostgreSQL database
"""

import pandas as pd
import sqlalchemy
from sqlalchemy import create_engine
from time import time
import argparse
import os

def main(params):
    """
    Main function to ingest CSV data into PostgreSQL
    """
    user = params.user
    password = params.password
    host = params.host
    port = params.port
    db = params.db
    table_name = params.table_name
    csv_file = params.csv_file

    # Validate file exists
    if not os.path.exists(csv_file):
        print(f"❌ Error: File not found: {csv_file}")
        return

    # Create database engine
    engine = create_engine(f'postgresql://{user}:{password}@{host}:{port}/{db}')

    print(f"📊 Loading data from: {csv_file}")
    print(f"📍 Target table: {table_name}")
    print(f"🔗 Database: {db} on {host}:{port}")
    print("")
    
    # Read CSV in chunks to handle large files
    df_iter = pd.read_csv(csv_file, iterator=True, chunksize=100000)
    
    # Get first chunk to create table
    df = next(df_iter)
    
    # Convert datetime columns based on taxi type
    if 'tpep_pickup_datetime' in df.columns:
        # Yellow taxi
        df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
        df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)
    elif 'lpep_pickup_datetime' in df.columns:
        # Green taxi
        df.lpep_pickup_datetime = pd.to_datetime(df.lpep_pickup_datetime)
        df.lpep_dropoff_datetime = pd.to_datetime(df.lpep_dropoff_datetime)
    
    # Create table with first chunk
    print("🔨 Creating table schema...")
    df.head(0).to_sql(name=table_name, con=engine, if_exists='replace')
    
    # Insert first chunk
    df.to_sql(name=table_name, con=engine, if_exists='append')
    
    print(f"✅ Inserted first chunk: {len(df):,} rows")
    
    # Insert remaining chunks
    chunk_num = 1
    total_rows = len(df)
    
    while True:
        try:
            t_start = time()
            df = next(df_iter)
            
            # Convert datetime columns
            if 'tpep_pickup_datetime' in df.columns:
                df.tpep_pickup_datetime = pd.to_datetime(df.tpep_pickup_datetime)
                df.tpep_dropoff_datetime = pd.to_datetime(df.tpep_dropoff_datetime)
            elif 'lpep_pickup_datetime' in df.columns:
                df.lpep_pickup_datetime = pd.to_datetime(df.lpep_pickup_datetime)
                df.lpep_dropoff_datetime = pd.to_datetime(df.lpep_dropoff_datetime)
            
            df.to_sql(name=table_name, con=engine, if_exists='append')
            
            t_end = time()
            chunk_num += 1
            total_rows += len(df)
            
            print(f'✅ Inserted chunk {chunk_num}: {len(df):,} rows (took {t_end - t_start:.3f}s) | Total: {total_rows:,}')
            
        except StopIteration:
            print("")
            print(f"🎉 Finished loading {table_name}")
            print(f"📊 Total rows inserted: {total_rows:,}")
            break
        except Exception as e:
            print(f"❌ Error: {e}")
            break

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Ingest NYC Taxi CSV data to PostgreSQL')
    
    parser.add_argument('--user', default='root', help='PostgreSQL username')
    parser.add_argument('--password', default='root', help='PostgreSQL password')
    parser.add_argument('--host', default='localhost', help='PostgreSQL host')
    parser.add_argument('--port', default='5432', help='PostgreSQL port')
    parser.add_argument('--db', default='ny_taxi', help='PostgreSQL database name')
    parser.add_argument('--table_name', required=True, help='Target table name')
    parser.add_argument('--csv_file', required=True, help='Path to CSV file')
    
    args = parser.parse_args()
    
    main(args)
