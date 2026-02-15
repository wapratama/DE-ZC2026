#!/bin/bash

# Script to download NYC Taxi data for 2019-2020
# DataTalks.Club Data Engineering Zoomcamp - Module 4

echo "=========================================="
echo "NYC Taxi Data Download Script"
echo "=========================================="
echo ""
echo "This will download ~2GB of taxi trip data"
echo "Years: 2019-2020"
echo "Types: Yellow Taxi, Green Taxi, Zone Lookup"
echo ""

# Create data directory if it doesn't exist
mkdir -p raw
cd raw

# Download Yellow Taxi Data (2019)
echo "📥 Downloading Yellow Taxi 2019 data..."
for month in $(seq -f "%02g" 1 12); do
    echo "  - Month $month/12"
    wget -q --show-progress https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2019-${month}.csv.gz
done

# Download Yellow Taxi Data (2020)
echo "📥 Downloading Yellow Taxi 2020 data..."
for month in $(seq -f "%02g" 1 12); do
    echo "  - Month $month/12"
    wget -q --show-progress https://github.com/DataTalksClub/nyc-tlc-data/releases/download/yellow/yellow_tripdata_2020-${month}.csv.gz
done

# Download Green Taxi Data (2019)
echo "📥 Downloading Green Taxi 2019 data..."
for month in $(seq -f "%02g" 1 12); do
    echo "  - Month $month/12"
    wget -q --show-progress https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-${month}.csv.gz
done

# Download Green Taxi Data (2020)
echo "📥 Downloading Green Taxi 2020 data..."
for month in $(seq -f "%02g" 1 12); do
    echo "  - Month $month/12"
    wget -q --show-progress https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2020-${month}.csv.gz
done

# Download Taxi Zone Lookup Table
echo "📥 Downloading Taxi Zone Lookup..."
wget -q --show-progress https://d37ci6vzurychx.cloudfront.net/misc/taxi+_zone_lookup.csv

echo ""
echo "✅ Download complete!"
echo "📁 Files saved in: $(pwd)"
echo ""

# Decompress files
echo "📦 Decompressing files..."
gunzip -f *.csv.gz

echo ""
echo "✅ All data ready!"
echo ""
echo "📊 Data Summary:"
echo "  - Yellow Taxi files: $(ls yellow_tripdata_*.csv | wc -l)"
echo "  - Green Taxi files: $(ls green_tripdata_*.csv | wc -l)"  
echo "  - Zone Lookup: taxi+_zone_lookup.csv"
echo ""
echo "💾 Total size: $(du -sh . | cut -f1)"
echo ""
echo "Next step: Load data using ingest_data.py"
