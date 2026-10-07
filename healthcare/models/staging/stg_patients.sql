{{ config(materialized='ephemeral') }}

SELECT
    patient_id,
    TRIM(UPPER(first_name))                                 AS first_name,
    TRIM(UPPER(last_name))                                  AS last_name,
    TRY_TO_DATE(date_of_birth)                              AS date_of_birth,
    DATEDIFF('year', TRY_TO_DATE(date_of_birth), CURRENT_DATE) AS age,
    UPPER(TRIM(gender))                                     AS gender,
    UPPER(TRIM(insurance_type))                             AS insurance_type,
    primary_provider_id,
    TRY_TO_DATE(registration_date)                          AS registration_date,
    updated_at,
    _loaded_at,
    _source_file
FROM {{ source('healthcare', 'raw_patients') }}
WHERE patient_id IS NOT NULL
