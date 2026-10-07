{{ config(materialized='ephemeral') }}

SELECT
    provider_id,
    TRIM(provider_name)             AS provider_name,
    UPPER(TRIM(specialty))          AS specialty,
    UPPER(TRIM(provider_type))      AS provider_type,
    TRIM(city)                      AS city,
    UPPER(TRIM(state))              AS state,
    npi_number,
    is_active,
    updated_at,
    _loaded_at
FROM {{ source('healthcare', 'raw_providers') }}
WHERE provider_id IS NOT NULL
