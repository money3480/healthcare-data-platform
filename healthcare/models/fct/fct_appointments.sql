{{ config(
    materialized='incremental',
    unique_key='appointment_id',
    incremental_strategy='delete+insert',
    on_schema_change='sync_all_columns'
) }}

SELECT
    appointment_id,
    patient_id,
    provider_id,
    scheduled_at,
    actual_start_at,
    status,
    appointment_type,
    wait_days,
    appointment_notes,
    updated_at
FROM {{ ref('stg_appointments') }}

{% if is_incremental() %}
    WHERE updated_at > (SELECT MAX(updated_at) FROM {{ this }})
{% endif %}
