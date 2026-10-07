-- ============================================================
-- 02_create_raw_tables.sql
-- Raw (Bronze) tables — exact source copy + ingestion metadata
-- ============================================================

USE DATABASE HEALTHCARE;
USE SCHEMA RAW;

CREATE TABLE IF NOT EXISTS RAW.raw_patients (
    patient_id              STRING        NOT NULL,
    first_name              STRING,
    last_name               STRING,
    date_of_birth           DATE,
    gender                  STRING,
    address                 STRING,
    phone                   STRING,
    insurance_type          STRING,
    primary_provider_id     STRING,
    registration_date       DATE,
    updated_at              TIMESTAMP_NTZ,
    -- Ingestion metadata
    _loaded_at              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file            STRING
);

CREATE TABLE IF NOT EXISTS RAW.raw_providers (
    provider_id             STRING        NOT NULL,
    provider_name           STRING,
    specialty               STRING,
    provider_type           STRING,
    city                    STRING,
    state                   STRING,
    npi_number              STRING,
    is_active               BOOLEAN,
    updated_at              TIMESTAMP_NTZ,
    _loaded_at              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file            STRING
);

CREATE TABLE IF NOT EXISTS RAW.raw_claims (
    claim_id                STRING        NOT NULL,
    patient_id              STRING,
    provider_id             STRING,
    diagnosis_code          STRING,
    claim_amount            NUMBER(12, 2),
    claim_date              DATE,
    claim_status            STRING,
    is_emergency            BOOLEAN,
    days_in_hospital        INTEGER,
    updated_at              TIMESTAMP_NTZ,
    _loaded_at              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file            STRING
);

CREATE TABLE IF NOT EXISTS RAW.raw_appointments (
    appointment_id          STRING        NOT NULL,
    patient_id              STRING,
    provider_id             STRING,
    scheduled_at            TIMESTAMP_NTZ,
    actual_start_at         TIMESTAMP_NTZ,
    status                  STRING,
    appointment_type        STRING,
    booked_date             DATE,
    appointment_notes       STRING,
    updated_at              TIMESTAMP_NTZ,
    _loaded_at              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _source_file            STRING
);

-- Ops table for pipeline alerts
CREATE TABLE IF NOT EXISTS OPS.pipeline_alerts (
    alert_id                NUMBER AUTOINCREMENT PRIMARY KEY,
    alert_type              STRING,
    message                 STRING,
    created_at              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
