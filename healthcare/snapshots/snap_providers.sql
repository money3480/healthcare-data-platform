{% snapshot snap_providers %}

{{
    config(
        target_schema='snapshots',
        unique_key='provider_id',
        strategy='timestamp',
        updated_at='updated_at'
    )
}}

SELECT
    provider_id,
    provider_name,
    specialty,
    provider_type,
    city,
    state,
    npi_number,
    is_active,
    _loaded_at,
    updated_at
FROM {{ ref('stg_providers') }}

{% endsnapshot %}