# Dockerfile
FROM python:3.11-slim

# ── System dependencies: Java (required by Spark) ────────────────────────────
RUN apt-get update && apt-get install -y \
    default-jdk \
    curl \
    wget \
    procps \
    && rm -rf /var/lib/apt/lists/*

# ── Set JAVA_HOME so PySpark can find it ─────────────────────────────────────
ENV JAVA_HOME=/usr/lib/jvm/default-java
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# ── Install uv inside the container ──────────────────────────────────────────
RUN pip install uv

# ── Set working directory ─────────────────────────────────────────────────────
WORKDIR /app

# ── Copy dependency files first (layer caching — faster rebuilds) ─────────────
COPY pyproject.toml uv.lock ./

# ── Install Python dependencies using uv (reads uv.lock for exact versions) ──
RUN uv sync --frozen

# ── Copy the rest of the project ─────────────────────────────────────────────
COPY . .

# ── Make uv's venv the default Python ────────────────────────────────────────
ENV PATH="/app/.venv/bin:${PATH}"
ENV VIRTUAL_ENV="/app/.venv"

# ── Spark environment variables ───────────────────────────────────────────────
ENV PYSPARK_PYTHON=/app/.venv/bin/python
ENV PYSPARK_DRIVER_PYTHON=/app/.venv/bin/python

# Default command: open a bash shell
CMD ["/bin/bash"]