{# dim_providers is built from the snap_providers snapshot — current rows only #}
{{ config(
    materialized='table',
    contract={'enforced': true}
) }}

SELECT
    provider_id,
    provider_name,
    specialty,
    provider_type,
    city,
    state,
    npi_number,
    is_active,
    dbt_valid_from                          AS valid_from,
    dbt_updated_at                          AS last_updated_at
FROM {{ ref('snap_providers') }}
