{{ config(materialized='ephemeral') }}

SELECT
    appointment_id,
    patient_id,
    provider_id,
    scheduled_at::TIMESTAMP_NTZ             AS scheduled_at,
    actual_start_at::TIMESTAMP_NTZ          AS actual_start_at,
    LOWER(TRIM(status))                     AS status,
    LOWER(TRIM(appointment_type))           AS appointment_type,
    DATEDIFF('day',
        booked_date::DATE,
        scheduled_at::DATE)                 AS wait_days,
    appointment_notes,
    updated_at::TIMESTAMP_NTZ           AS updated_at,
    _loaded_at
FROM {{ source('healthcare', 'raw_appointments') }}
WHERE appointment_id IS NOT NULL
