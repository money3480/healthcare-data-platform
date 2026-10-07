{# dim_patients is built from the snap_patients snapshot — current rows only #}
{{ config(
    materialized='table',
    contract={'enforced': true}
) }}

SELECT
    patient_id,
    first_name,
    last_name,
    date_of_birth,
    age,
    gender,
    insurance_type,
    primary_provider_id,
    registration_date,
    dbt_valid_from                          AS valid_from,
    dbt_updated_at                          AS last_updated_at
FROM {{ ref('snap_patients') }}
WHERE dbt_valid_to IS NULL
