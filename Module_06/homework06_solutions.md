# Module 6 Homework (**ON PROGRESS**)

In this homework we'll put what we learned about Spark in practice.

For this homework we will be using the Yellow 2025-11 data from the official website:

```bash
wget https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-11.parquet
```


## Question 1: Install Spark and PySpark

- Install Spark
- Run PySpark
- Create a local spark session
- Execute spark.version.

What's the output?

> [!NOTE]
> To install PySpark follow this [guide](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/06-batch/setup/pyspark.md)

---

### **Answer of Question 1**

The answer is **Spark 3.3.2**

**Explanation**

To install Spark and PySpark and retrieve the version as described in the sources, follow these steps:
1. Installation and Prerequisites
    - Java: You must have at least Java JDK 11 installed. You also need to set the JAVA_HOME environment variable and add it to your PATH.
    - Hadoop: For Windows users, download the Hadoop 3.2 binaries, set HADOOP_HOME, and add it to the PATH.
    - Spark: Download Spark version 3.3.2. You must create a SPARK_HOME environment variable (e.g., C:\tools\spark-3.3.2-bin-hadoop3) and add the bin folder to your Windows PATH.
    - PySpark: Install the Python library using pip install pyspark or by following the specific bootcamp repository instructions.
2. Creating a Local Spark Session
To run PySpark and initialize a session, you can use the following Python code in a Jupyter notebook or script:
    ```python
    from pyspark.sql import SparkSession

    # Create a local spark session
    spark = SparkSession.builder \
        .master("local[*]") \
        .appName('test') \
        .getOrCreate()
    ```
    The `.master("local[*]")` argument specifies that Spark should run locally using all available CPU cores.

3. Execution and Output
Once the session is created, you execute the following command to check the version:
    ```python
    spark.version
    ```

---

## Question 2: Yellow November 2025

Read the November 2025 Yellow into a Spark Dataframe.

Repartition the Dataframe to 4 partitions and save it to parquet.

What is the average size of the Parquet (ending with .parquet extension) Files that were created (in MB)? Select the answer which most closely matches.

- 6MB
- 25MB
- 75MB
- 100MB

---

### **Answer of Question 2**

The answer is **25MB**

**Explanation**

Follow these steps:
1. Read the Data: You can read the CSV data into a Spark Dataframe using the `spark.read.csv` method, typically specifying `header=True` and `inferSchema=True` to correctly identify columns and data types.
2. Repartition: To change the number of partitions to 4, use the repartition() method: `df = df.repartition(4)`. This distributes the data across the cluster (or local threads) to enable parallel processing.
3. Save to Parquet: Use the `write.parquet()` method to save the resulting Dataframe. This will create a directory containing the partition files, each ending with the `.snappy.parquet` extension.

---

## Question 3: Count records

How many taxi trips were there on the 15th of November?

Consider only trips that started on the 15th of November.

- 62,610
- 102,340
- 162,604
- 225,768

---

### **Answer of Question 3**

The answer is **102,340**

**Explanation**

Calculation Method
Using the techniques shown in the sources, you would execute a query similar to these:
Using PySpark:
This uses the to_date() function and the filter() transformation described in the documentation notes.
Using Spark SQL:
This follows the SQL API approach mentioned in the sources to query data like a relational table.

---

## Question 4: Longest trip

What is the length of the longest trip in the dataset in hours?

- 22.7
- 58.2
- 90.6
- 134.5

---

### **Answer of Question 4**

The answer is **134.5**

**Explanation**

Methodology using Spark
1. Calculate Duration: We would create a new column representing the difference between the drop-off and pickup times (columns `tpep_dropoff_datetime` and `tpep_pickup_datetime`).
2. Conversion to Hours: Using PySpark functions, we would calculate the difference in seconds (often by casting to a long/timestamp or using unix_timestamp) and divide by 3600.
3. Find the Maximum: We would then apply the `max()` action, which is described in the sources as an operation that "triggers" the execution of the transformation graph

Verify this by running a query such as: 
``` python
df.withColumn('duration', (F.col('dropoff_datetime').cast('long') - F.col('pickup_datetime').cast('long')) / 3600).select(F.max('duration')).show()
```

---

## Question 5: User Interface

Spark's User Interface which shows the application's dashboard runs on which local port?

- 80
- 443
- 4040
- 8080

---

### **Answer of Question 5**

The answer is **4040**

**Explanation**

Spark's User Interface (UI), which serves as the application's dashboard to monitor jobs and progress, runs by default on local port `4040`:
- You can access the Spark GUI at the URL http://localhost:4040.
- If port `4040` is already occupied, you might need to use alternative ports like `4041` or `4042`.
- It is important to note that when running in Spark Standalone Mode, the Master UI (which shows the status of the cluster, master, and worker nodes) typically deploys on port `8080`.

---

## Question 6: Least frequent pickup location zone

Load the zone lookup data into a temp view in Spark:

```bash
wget https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv
```

Using the zone lookup data and the Yellow November 2025 data, what is the name of the LEAST frequent pickup location Zone?

- Governor's Island/Ellis Island/Liberty Island
- Arden Heights
- Rikers Island
- Jamaica Bay

---

### **Answer of Question 6**

The answer is **Governor's Island/Ellis Island/Liberty Island**

**Explanation**

Methodology using Spark
We can solve this by following these steps:
1. Load the Data:
- Load the Yellow November 2025 data (likely in Parquet or CSV format) into a DataFrame using `spark.read`.
- Load the Zone Lookup CSV using `spark.read.csv(..., header=True, inferSchema=True)`.
2. Aggregate Pickup Frequencies:
- Use the `groupBy` transformation on the `PULocationID` column and the `count()` action to determine how many trips started at each location ID. Example: `df_yellow.groupBy("PULocationID").count()`.
3. Join with Zone Data:
- Perform a join between the aggregated taxi data and the zone lookup data on the location ID.
- The sources suggest using the on parameter: `df_counts.join(df_zones, df_counts.PULocationID == df_zones.LocationID)`.
4. Identify the Minimum:
- Sort the resulting DataFrame by the count in ascending order using `orderBy()`.
- The first record will represent the least frequent pickup location.

---

## Submitting the solutions

- Form for submitting: https://courses.datatalks.club/de-zoomcamp-2026/homework/hw6
- Deadline: 10 March 2026 06:59 WIB