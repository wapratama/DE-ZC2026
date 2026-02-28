"""Pipeline to ingest NYC taxi data from the Data Engineering Zoomcamp REST API."""

import dlt
from dlt.sources.rest_api import rest_api_resources
from dlt.sources.rest_api.typing import RESTAPIConfig


@dlt.source
def taxi_rest_api_source():
    """Define dlt resources from the NYC taxi REST API (page-based pagination)."""
    config: RESTAPIConfig = {
        "client": {
            "base_url": (
                "https://us-central1-dlthub-analytics.cloudfunctions.net"
                "/data_engineering_zoomcamp_api"
            ),
        },
        "resources": [
            {
                "name": "trips",
                "endpoint": {
                    "path": "",
                    "data_selector": "$",
                    "paginator": {
                        "type": "page_number",
                        "page_param": "page",
                        "base_page": 1,
                        "maximum_page": 20,
                        "stop_after_empty_page": True,
                        "total_path": None,
                    },
                },
            },
        ],
    }

    yield from rest_api_resources(config)


pipeline = dlt.pipeline(
    pipeline_name="taxi_pipeline",
    destination="duckdb",
    refresh="drop_sources",
    progress="log",
)


if __name__ == "__main__":
    load_info = pipeline.run(taxi_rest_api_source())
    print(load_info)