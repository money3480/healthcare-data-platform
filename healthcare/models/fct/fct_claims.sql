{{ config(
    materialized='incremental',
    unique_key='claim_id',
    incremental_strategy='delete+insert',
    on_schema_change='sync_all_columns'
) }}

SELECT
    claim_id,
    patient_id,
    provider_id,
    diagnosis_code,
    claim_amount,
    claim_date,
    claim_status,
    is_emergency,
    days_in_hospital,
    CASE
        WHEN claim_amount < 500   THEN 'low'
        WHEN claim_amount < 5000  THEN 'medium'
        ELSE 'high'
    END                                     AS claim_amount_band,
    updated_at::TIMESTAMP_NTZ               AS updated_at
FROM {{ ref('stg_claims') }}

{% if is_incremental() %}
    WHERE updated_at > (SELECT MAX(updated_at) FROM {{ this }})
{% endif %}
