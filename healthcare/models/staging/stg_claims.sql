{{ config(materialized='ephemeral') }}

SELECT
    claim_id,
    patient_id,
    provider_id,
    UPPER(TRIM(diagnosis_code))     AS diagnosis_code,
    TRY_TO_DECIMAL(claim_amount, 12, 2) AS claim_amount,
    TRY_TO_DATE(claim_date)         AS claim_date,
    LOWER(TRIM(claim_status))       AS claim_status,
    is_emergency::BOOLEAN           AS is_emergency,
    days_in_hospital::INTEGER       AS days_in_hospital,
    updated_at::TIMESTAMP_NTZ           AS updated_at,
    _loaded_at
FROM {{ source('healthcare', 'raw_claims') }}
WHERE claim_id IS NOT NULL
  AND patient_id IS NOT NULL
