-- ============================================================
-- 03_create_stages_and_pipes.sql
-- Script to create stages and pipes using the data in the S3 bucket
-- Run in Snowflake
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
    URL         = 's3://healthcare-data-platform-test/patients/'
    CREDENTIALS = (AWS_KEY_ID="{{ env_var('AWS_ACCESS_KEY_ID') }}" AWS_SECRET_KEY="{{ env_var('AWS_SECRET_ACCESS_KEY') }}")
    FILE_FORMAT = raw.csv_format;

CREATE STAGE IF NOT EXISTS raw.s3_providers_stage
    URL         = 's3://healthcare-data-platform-test/providers/'
    CREDENTIALS = (AWS_KEY_ID="{{ env_var('AWS_ACCESS_KEY_ID') }}" AWS_SECRET_KEY="{{ env_var('AWS_SECRET_ACCESS_KEY') }}")
    FILE_FORMAT = raw.csv_format;

CREATE STAGE IF NOT EXISTS raw.s3_claims_stage
    URL         = 's3://healthcare-data-platform-test/claims/'
    CREDENTIALS = (AWS_KEY_ID="{{ env_var('AWS_ACCESS_KEY_ID') }}" AWS_SECRET_KEY="{{ env_var('AWS_SECRET_ACCESS_KEY') }}")
    FILE_FORMAT = raw.json_format;

CREATE STAGE IF NOT EXISTS raw.s3_appointments_stage
    URL         = 's3://healthcare-data-platform-test/appointments/'
    CREDENTIALS = (AWS_KEY_ID="{{ env_var('AWS_ACCESS_KEY_ID') }}" AWS_SECRET_KEY="{{ env_var('AWS_SECRET_ACCESS_KEY') }}")
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

CREATE PIPE IF NOT EXISTS raw.claims_pipe
    AUTO_INGEST = TRUE
    COMMENT     = 'Loads new claims JSON files from S3 automatically'
AS
    COPY INTO raw.raw_claims (
        claim_id, patient_id, provider_id, diagnosis_code,
        claim_amount, claim_date, claim_status, is_emergency,
        days_in_hospital, updated_at, _source_file
    )
    FROM (
        SELECT
            $1:claim_id::STRING,
            $1:patient_id::STRING,
            $1:provider_id::STRING,
            $1:diagnosis_code::STRING,
            $1:claim_amount::NUMBER(12,2),
            $1:claim_date::DATE,
            $1:claim_status::STRING,
            $1:is_emergency::BOOLEAN,
            $1:days_in_hospital::INTEGER,
            $1:updated_at::TIMESTAMP_NTZ,
            METADATA$FILENAME
        FROM @raw.s3_claims_stage
    )
    FILE_FORMAT = raw.json_format;

CREATE PIPE IF NOT EXISTS raw.appointments_pipe
    AUTO_INGEST = TRUE
    COMMENT     = 'Loads new appointment CSV files from S3 automatically'
AS
    COPY INTO raw.raw_appointments (
        appointment_id, patient_id, provider_id,
        scheduled_at, actual_start_at,
        status, appointment_type, booked_date,
        appointment_notes, updated_at, _source_file
    )
    FROM (
        SELECT
            $1, $2, $3,
            $4::TIMESTAMP_NTZ, $5::TIMESTAMP_NTZ,
            $6, $7, $8::DATE,
            $9, $10::TIMESTAMP_NTZ,
            METADATA$FILENAME
        FROM @raw.s3_appointments_stage
    )
    FILE_FORMAT = raw.csv_format;

-- ── After creating pipes ──────────────────────────────────────
-- Run: SHOW PIPES IN SCHEMA HEALTHCARE.RAW;
-- Copy the notification_channel ARN for each pipe and add as an
-- S3 event notification (ObjectCreated) on the matching S3 prefix.

-- ── Manually refresh pipes for files already in S3 ───────────
-- Run these after setting up S3 event notifications:
-- ALTER PIPE HEALTHCARE.RAW.patients_pipe     REFRESH;
-- ALTER PIPE HEALTHCARE.RAW.providers_pipe    REFRESH;
-- ALTER PIPE HEALTHCARE.RAW.claims_pipe       REFRESH;
-- ALTER PIPE HEALTHCARE.RAW.appointments_pipe REFRESH;
