{{ config(materialized='table') }}

SELECT
    provider_id,
    provider_name,
    specialty,
    provider_type,
    city,
    state,
    npi_number,
    is_active
FROM {{ ref('stg_providers') }}
