{# dim_providers is built from the snap_providers snapshot — current rows only #}
{{ config(
    materialized='table',
    contract={'enforced': true}
) }}

SELECT
    provider_id::VARCHAR                    AS provider_id,
    provider_name::VARCHAR                  AS provider_name,
    specialty::VARCHAR                      AS specialty,
    provider_type::VARCHAR                  AS provider_type,
    city::VARCHAR                           AS city,
    state::VARCHAR                          AS state,
    npi_number::VARCHAR                     AS npi_number,
    is_active::BOOLEAN                      AS is_active,
    dbt_valid_from::TIMESTAMP_NTZ           AS valid_from,
    dbt_updated_at::TIMESTAMP_NTZ           AS last_updated_at
FROM {{ ref('snap_providers') }}
WHERE dbt_valid_to IS NULL
