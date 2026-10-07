-- ============================================================
-- 03_create_stages_and_pipes.sql
-- Replace <YOUR_S3_BUCKET> with your actual bucket name
-- Replace <YOUR_AWS_KEY> and <YOUR_AWS_SECRET> with credentials
-- Or use a Snowflake Storage Integration (recommended for production)
-- ============================================================

USE DATABASE HEALTHCARE;
USE SCHEMA RAW;
USE ROLE TRANSFORM;

-- ── File formats ─────────────────────────────────────────────
CREATE FILE FORMAT IF NOT EXISTS raw.csv_format
    TYPE             = 'CSV'
    FIELD_DELIMITER  = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER      = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF          = ('NULL', 'null', '')
    EMPTY_FIELD_AS_NULL = TRUE;

CREATE FILE FORMAT IF NOT EXISTS raw.json_format
    TYPE             = 'JSON'
    STRIP_OUTER_ARRAY = TRUE;

-- ── External stages ──────────────────────────────────────────
CREATE STAGE IF NOT EXISTS raw.s3_patients_stage
    URL         = 's3://<YOUR_S3_BUCKET>/patients/'
    CREDENTIALS = (AWS_KEY_ID='<YOUR_AWS_KEY>' AWS_SECRET_KEY='<YOUR_AWS_SECRET>')
    FILE_FORMAT = raw.csv_format;

CREATE STAGE IF NOT EXISTS raw.s3_providers_stage
    URL         = 's3://<YOUR_S3_BUCKET>/providers/'
    CREDENTIALS = (AWS_KEY_ID='<YOUR_AWS_KEY>' AWS_SECRET_KEY='<YOUR_AWS_SECRET>')
    FILE_FORMAT = raw.csv_format;

CREATE STAGE IF NOT EXISTS raw.s3_claims_stage
    URL         = 's3://<YOUR_S3_BUCKET>/claims/'
    CREDENTIALS = (AWS_KEY_ID='<YOUR_AWS_KEY>' AWS_SECRET_KEY='<YOUR_AWS_SECRET>')
    FILE_FORMAT = raw.json_format;

CREATE STAGE IF NOT EXISTS raw.s3_appointments_stage
    URL         = 's3://<YOUR_S3_BUCKET>/appointments/'
    CREDENTIALS = (AWS_KEY_ID='<YOUR_AWS_KEY>' AWS_SECRET_KEY='<YOUR_AWS_SECRET>')
    FILE_FORMAT = raw.csv_format;

-- ── Snowpipes (AUTO_INGEST requires SQS notification on S3) ──
CREATE PIPE IF NOT EXISTS raw.patients_pipe
    AUTO_INGEST = TRUE
    COMMENT     = 'Loads new patient CSV files from S3 automatically'
AS
    COPY INTO raw.raw_patients (
        patient_id, first_name, last_name, date_of_birth, gender,
        address, phone, insurance_type, primary_provider_id,
        registration_date, updated_at, _source_file
    )
    FROM (
        SELECT
            $1, $2, $3, $4::DATE, $5,
            $6, $7, $8, $9,
            $10::DATE, $11::TIMESTAMP_NTZ,
            METADATA$FILENAME
        FROM @raw.s3_patients_stage
    )
    FILE_FORMAT = raw.csv_format;

CREATE PIPE IF NOT EXISTS raw.providers_pipe
    AUTO_INGEST = TRUE
    COMMENT     = 'Loads new provider CSV files from S3 automatically'
AS
    COPY INTO raw.raw_providers (
        provider_id, provider_name, specialty, provider_type,
        city, state, npi_number, is_active, updated_at, _source_file
    )
    FROM (
        SELECT
            $1, $2, $3, $4,
            $5, $6, $7, $8::BOOLEAN, $9::TIMESTAMP_NTZ,
            METADATA$FILENAME
        FROM @raw.s3_providers_stage
    )
    FILE_FORMAT = raw.csv_format;

-- After creating pipes, run:
--   SHOW PIPES;
-- Copy the notification_channel ARN for each pipe and add it as an
-- S3 event notification (ObjectCreated) on the corresponding S3 prefix.

-- ── Manual COPY INTO (use when S3 event notifications not set up yet) ──
-- COPY INTO raw.raw_patients FROM @raw.s3_patients_stage ON_ERROR = 'CONTINUE';
-- COPY INTO raw.raw_providers FROM @raw.s3_providers_stage ON_ERROR = 'CONTINUE';
