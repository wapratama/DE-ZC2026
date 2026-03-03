# Workshop
From APIs to Warehouses: AI-Assisted Data Ingestion with dlt
---

## Folder Description
This Workshop folder is part of my learning and homework exercise. You will see:
- dlt: original dlt workshop repo from [DataTalksClub](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/cohorts/2026/workshops/dlt).
- Experiment: My exercise to build data pipeline from the [Open Library API](https://openlibrary.org/developers/api).
- taxi-pipeline: My homework exercise to build pipeline for NYC Yellow Taxi trip data from a custom API using this [link](https://us-central1-dlthub-analytics.cloudfunctions.net/data_engineering_zoomcamp_api).
- homework: My submitted homework for DE Zoomcamp 2026.

## How to run
For this case, I want to run my homework exercise (taxi-pipeline):
- Go to the exercise folder
    ```bash
    cd taxi-pipeline
    ```

- Recreate venv and reinstall packages
    ```bash
    uv venv
    source .venv/Scripts/activate
    uv sync
    ```

- Run the pipeline
    ```bash
    uv run python taxi_pipeline.py
    ```
-  Inspect Pipeline Data with the dlt Dashboard
    
    Once your pipeline runs successfully, launch the dashboard to inspect your data and metadata:

    ```bash
    uv run dlt pipeline taxi_pipeline show
    ```
- Inspect the Pipeline using AI Agent

    You can also ask the AI about your pipeline directly using chat from your own IDE

- Finish your exercise activity with quit from dlt dashboard and deactivate the virtual environment.

    ```bash
    # Deactivate your virtual environment
    deactivate
    ```

## Cleanup After Exercise
For this exercise, everything dlt creates is local only and no cloud, no external services. Here's exactly what to delete and what to keep:
- Step 1 — Delete the DuckDB database (biggest file)
    ```bash
    cd taxi-pipeline
    ```

- Check size first
    ```bash
    ls -lh *.duckdb
    ```

- Delete it 

    Do it carefully, make sure you are inside the exercise folder.
    ```bash
    rm taxi_pipeline.duckdb
    rm -f taxi_pipeline.duckdb.wal  # delete WAL file too if exists
    ```

- Delete dlt pipeline state
    ```bash
    # dlt stores pipeline state here — safe to delete
    rm -rf .dlt/pipelines/
    ```

    WARNING: 
    
    ⚠️ Do NOT delete the entire `.dlt/` folder — it also contains your
    `config.toml` and `secrets.toml` which belong to your project. Also never push this folder to your repo.

- Delete the virtual environment
    ```bash
    # The .venv folder is large (~200-500MB with all packages)
    rm -rf .venv/
    ```

- Clear uv package cache (optional, if needed)
    ```bash
    # This clears ALL cached packages across all uv projects
    uv cache clean
    ```

- Verify what's left (should be small)
    ```bash
    ls -lah
    ```