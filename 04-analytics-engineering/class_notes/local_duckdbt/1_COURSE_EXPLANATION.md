**Module 4: Analytics Engineering**
# Task 1 — What Module 04 (Analytics Engineering) is about — deep, practical explanation

### High-level goal

Module 04 teaches you how to **transform raw DWH tables into production-ready analytical models** using an analytics engineering workflow (SQL + tooling), with emphasis on **repeatability, testing, documentation, and deployment**. The central technology here is **dbt** (data build tool), and the course materials live in the DataTalksClub repo: [DataTalksClub/data-engineering-zoomcamp.](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/04-analytics-engineering)

---

## Why this module matters (practical value)

* **Analysts consume models, not raw tables.** A good analytics engineer produces curated, documented, tested views that analysts and BI tools trust.
* **Repeatability & lineage.** dbt makes transformations code-centric (SQL + config), so you can version, test, and document models.
* **Cost & performance awareness.** You learn to design models that are efficient in a cloud DWH (partitioning, pruning, materialization choices).
* **Professional practices.** Built-in CI friendliness, docs generation, and deployment patterns that mirror real teams.

---

## Core concepts you’ll master

### 1. dbt project layout & artifacts

* `models/` — SQL files that define transformations (select statements).
* `macros/` — reusable SQL snippets (Jinja).
* `seeds/` — small CSVs versioned in repo and loaded as tables.
* `tests/` — schema & data tests (uniqueness, not null, relationships).
* `snapshots/` — capture slowly changing or source state over time.
* `docs/` & `catalog` — auto-generated documentation and data lineage.

You’ll create, run, and iterate these artifacts.

---

### 2. Materializations & when to use them

dbt supports multiple runtime materializations (how model output is stored/exposed):

* **view** — lightweight, always-up-to-date, but re-computed on every query (cheap dev, slower runtime).
* **table** — persisted result, cheaper to query later but must be refreshed.
* **incremental** — append/update only new/changed rows (big wins for large datasets).
* **ephemeral** — inlined SQL used only at compile time (no table created).

Choosing materialization is a core design decision: performance vs freshness vs cost.

---

### 3. Testing & quality

dbt encourages test-driven transformations:

* **Schema tests** (e.g., `not_null`, `unique`) validate assumptions.
* **Custom data tests** (SQL assertions) check business logic (e.g., no negative fares).
* Tests run locally and in CI to avoid shipping broken models.

---

### 4. Documentation & lineage

dbt auto-generates docs from model `description` fields and shows dependency graphs (DAG). This gives analysts immediate lineage & column context — hugely valuable for trust and handovers.

---

### 5. CI / Deployment expectations

In production teams:

* `dbt run` + `dbt test` are invoked in CI (e.g., GitHub Actions).
* Artifacts (compiled SQL, docs) are stored and published.
* Deployments are scheduled or triggered by data arrival (orchestrators from Module 02).

---

## Two supported setups in the course (what they are and why both exist)

The course provides two implementation paths, documented in the repo:

* **Local Setup** — run dbt locally (usually with DuckDB or Postgres/DuckDB + local files). Great for quick iteration, no cloud costs. See the local setup guide in the repo. DataTalksClub/data-engineering-zoomcamp

* **Cloud Setup (BigQuery)** — run dbt against a cloud warehouse (BigQuery). Realistic for production, integrates with your Module 03 BigQuery datasets, supports large data and materializations that match enterprise usage. BigQuery is the target DWH. BigQuery

Both paths teach the same engineering principles; the difference is infra realism and scale.

---

## What the homework evaluates (practical checklist)

When you do the Module 04 homework you are expected to:

1. **Implement dbt models** that transform raw DWH tables into analytics tables/views.
2. **Add tests** that assert data quality and business rules.
3. **Document models** with descriptions and generate docs.
4. **Choose materializations** appropriately (views / tables / incremental) and justify choices.
5. **Produce runnable artifacts** (compiled SQL, docs) and show results (counts, sample queries).
6. (If using local setup) prove parity of results with the DWH inputs.

The homework usually asks for concrete SQL, test outputs, and short explanations: the grader cares about correctness, tests, and applied best practices.

---

## Typical day-to-day skills you’ll have after this module

* Create end-to-end dbt models from source to mart.
* Implement incremental loads for large facts.
* Write robust tests and use dbt’s `run`, `test`, `docs generate` workflows.
* Document models and inspect lineage.
* Understand production tradeoffs: cost, freshness, and query performance.

---

## Links & course materials (where you'll spend time)

* The main module folder and setup instructions: DataTalksClub/data-engineering-zoomcamp — follow `04-analytics-engineering/setup/*` for detailed steps.
* dbt docs & best practices (you’ll use them heavily): dbt Labs
* If you follow the Cloud path, you’ll reuse your Module 03 BigQuery datasets: BigQuery

---

## Concrete outputs you will hand in for the homework

* dbt project folder with `models/`, `tests/`, `profiles.yml` (or equivalent local config), and a README.
* A short report showing: model row counts, test results (pass/fail), sample queries, and rationale for materialization/test choices.
* Generated docs HTML (or a screenshot/hosted link) showing lineage.

---

### Bottom line (what success looks like)

You will finish Module 04 able to turn raw DWH tables into reliable, tested, documented analytics models — the exact role analytics engineers do daily. This module bridges data engineering (ingest + storage) and analytics (trusted, documented datasets).

---