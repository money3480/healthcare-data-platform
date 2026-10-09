{# dim_patients is built from the snap_patients snapshot — current rows only #}
{{ config(
    materialized='table',
    contract={'enforced': true}
) }}

SELECT
    patient_id::VARCHAR                     AS patient_id,
    first_name::VARCHAR                     AS first_name,
    last_name::VARCHAR                      AS last_name,
    date_of_birth::DATE                     AS date_of_birth,
    age::NUMBER(3, 0)                       AS age,
    gender::VARCHAR                         AS gender,
    insurance_type::VARCHAR                 AS insurance_type,
    primary_provider_id::VARCHAR            AS primary_provider_id,
    registration_date::DATE                 AS registration_date,
    dbt_valid_from::TIMESTAMP_NTZ           AS valid_from,
    dbt_updated_at::TIMESTAMP_NTZ           AS last_updated_at
FROM {{ ref('snap_patients') }}
WHERE dbt_valid_to IS NULL
