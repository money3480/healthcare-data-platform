# Healthcare Data Platform

An end-to-end healthcare analytics platform built with Snowflake, dbt, AWS S3, Python, and GitHub Actions CI/CD.

## Architecture

```
Synthetic Data (Python/Faker)
        │
        ▼
   AWS S3 (raw zone)
        │  Snowpipe (auto-ingest)
        ▼
Snowflake — Bronze (RAW schema)
        │  dbt staging models
        ▼
Snowflake — Silver (dim / fct)
   - dim_patients     (SCD Type 2 via dbt snapshot)
   - dim_providers
   - fct_claims       (incremental)
   - fct_appointments (incremental)
        │  dbt mart + Python models
        ▼
Snowflake — Gold (mart)
   - mart_claims_summary
   - mart_patient_risk_scores  (Python / Snowpark)
   - mart_provider_performance
```

## Tech Stack

| Layer | Technology |
|---|---|
| Ingestion | Python (Faker), AWS S3, Snowpipe |
| Warehouse | Snowflake |
| Transformation | dbt 1.11 (SQL + Python models) |
| Testing | dbt tests, dbt_expectations, custom generics |
| Orchestration | GitHub Actions (prod deploy + slim CI) |
| Auth | Key-pair authentication |

## Setup

### 1. Install dependencies
```bash
uv python install 3.13
uv sync
```

### 2. Set environment variables
Copy `set-env.ps1.example` to `set-env.ps1` and fill in your credentials, then:
```powershell
. .\set-env.ps1
```

### 3. Set up Snowflake
```bash
# Run the setup scripts in order
snowsql -f snowflake_setup/01_create_schemas.sql
snowsql -f snowflake_setup/02_create_raw_tables.sql
snowsql -f snowflake_setup/03_create_stages_and_pipes.sql
```

### 4. Generate and load data
```bash
uv run python data_generator/generate_data.py
uv run python data_generator/upload_to_s3.py
```

### 5. Run dbt
```bash
cd healthcare
uv run dbt deps
uv run dbt snapshot          # SCD2 for dim_patients
uv run dbt build             # build and test everything
uv run dbt docs generate
uv run dbt docs serve
```

## CI/CD

- **Prod deploy**: triggers on merge to `main` — runs `dbt build` against `PROD` schema
- **Slim CI**: triggers on PRs — tests only modified + downstream models deferred against prod manifest

## GitHub Secrets Required

| Secret | Description |
|---|---|
| `SNOWFLAKE_ACCOUNT` | e.g. `abc123.us-east-1` |
| `DBT_USER` | Snowflake service account username |
| `PRIVATE_KEY` | RSA private key PEM content |
| `PRIVATE_KEY_PASSPHRASE` | Passphrase for the private key |
| `S3_BUCKET` | Name of the raw S3 bucket |
| `AWS_ACCESS_KEY_ID` | AWS access key for S3 uploads |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
