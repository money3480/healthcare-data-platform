-- ============================================================
-- 04_load_data_no_s3.sql
-- Use this instead of script 03 when S3 is not yet set up.
-- Loads data from local CSV/JSON files via Snowflake internal stages.
--
-- STEP 1: Run this entire script in a Snowflake worksheet to create
--         the file formats and internal stages.
--
-- STEP 2: Use SnowSQL (CLI) from your local machine to PUT the files:
--
--   snowsql -a "{{ env_var('SNOWFLAKE_ACCOUNT') }}" -u dbt --private-key-path %TEMP%\healthcare_private_key.p8
--
--   Then inside SnowSQL:
--   PUT file://C:/Users/MARVINSCOTT/Desktop/Git Repositories/healthcare-platform/data_generator/data/providers.csv    @HEALTHCARE.RAW.stage_providers    AUTO_COMPRESS=FALSE;
--   PUT file://C:/Users/MARVINSCOTT/Desktop/Git Repositories/healthcare-platform/data_generator/data/patients.csv     @HEALTHCARE.RAW.stage_patients     AUTO_COMPRESS=FALSE;
--   PUT file://C:/Users/MARVINSCOTT/Desktop/Git Repositories/healthcare-platform/data_generator/data/claims.json      @HEALTHCARE.RAW.stage_claims       AUTO_COMPRESS=FALSE;
--   PUT file://C:/Users/MARVINSCOTT/Desktop/Git Repositories/healthcare-platform/data_generator/data/appointments.csv @HEALTHCARE.RAW.stage_appointments AUTO_COMPRESS=FALSE;
--
-- STEP 3: Run the COPY INTO statements at the bottom of this script.
-- ============================================================

USE DATABASE HEALTHCARE;
USE SCHEMA RAW;
USE ROLE TRANSFORM;

-- ── File formats ─────────────────────────────────────────────
CREATE FILE FORMAT IF NOT EXISTS raw.csv_format
    TYPE                         = 'CSV'
    FIELD_DELIMITER              = ','
    RECORD_DELIMITER             = '\n'
    SKIP_HEADER                  = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF                      = ('NULL', 'null', '')
    EMPTY_FIELD_AS_NULL          = TRUE;

CREATE FILE FORMAT IF NOT EXISTS raw.json_format
    TYPE              = 'JSON'
    STRIP_OUTER_ARRAY = FALSE;   -- generator writes one JSON object per line (JSONL)

-- ── Internal named stages (no S3 required) ───────────────────
CREATE STAGE IF NOT EXISTS raw.stage_providers    FILE_FORMAT = raw.csv_format;
CREATE STAGE IF NOT EXISTS raw.stage_patients     FILE_FORMAT = raw.csv_format;
CREATE STAGE IF NOT EXISTS raw.stage_claims       FILE_FORMAT = raw.json_format;
CREATE STAGE IF NOT EXISTS raw.stage_appointments FILE_FORMAT = raw.csv_format;

-- ── COPY INTO — run after PUT commands above ─────────────────

-- Providers
COPY INTO raw.raw_providers (
    provider_id, provider_name, specialty, provider_type,
    city, state, npi_number, is_active, updated_at, _source_file
)
FROM (
    SELECT
        $1, $2, $3, $4,
        $5, $6, $7, $8::BOOLEAN,
        $9::TIMESTAMP_NTZ,
        METADATA$FILENAME
    FROM @raw.stage_providers
)
FILE_FORMAT = raw.csv_format
ON_ERROR    = 'CONTINUE';

-- Patients
COPY INTO raw.raw_patients (
    patient_id, first_name, last_name, date_of_birth, gender,
    address, phone, insurance_type, primary_provider_id,
    registration_date, updated_at, _source_file
)
FROM (
    SELECT
        $1, $2, $3,
        $4::DATE, $5,
        $6, $7, $8, $9,
        $10::DATE, $11::TIMESTAMP_NTZ,
        METADATA$FILENAME
    FROM @raw.stage_patients
)
FILE_FORMAT = raw.csv_format
ON_ERROR    = 'CONTINUE';

-- Claims (JSONL — one object per line)
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
    FROM @raw.stage_claims
)
FILE_FORMAT = raw.json_format
ON_ERROR    = 'CONTINUE';

-- Appointments
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
    FROM @raw.stage_appointments
)
FILE_FORMAT = raw.csv_format
ON_ERROR    = 'CONTINUE';

-- ── Verify row counts ────────────────────────────────────────
SELECT 'raw_providers'    AS tbl, COUNT(*) AS rows FROM raw.raw_providers    UNION ALL
SELECT 'raw_patients'     AS tbl, COUNT(*) AS rows FROM raw.raw_patients     UNION ALL
SELECT 'raw_claims'       AS tbl, COUNT(*) AS rows FROM raw.raw_claims       UNION ALL
SELECT 'raw_appointments' AS tbl, COUNT(*) AS rows FROM raw.raw_appointments;
