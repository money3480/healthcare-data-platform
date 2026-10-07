{{ config(materialized='ephemeral') }}

SELECT
    appointment_id,
    patient_id,
    provider_id,
    TRY_TO_TIMESTAMP(scheduled_at)          AS scheduled_at,
    TRY_TO_TIMESTAMP(actual_start_at)       AS actual_start_at,
    LOWER(TRIM(status))                     AS status,
    LOWER(TRIM(appointment_type))           AS appointment_type,
    DATEDIFF('day',
        TRY_TO_DATE(booked_date),
        TRY_TO_DATE(scheduled_at))          AS wait_days,
    appointment_notes,
    updated_at,
    _loaded_at
FROM {{ source('healthcare', 'raw_appointments') }}
WHERE appointment_id IS NOT NULL
