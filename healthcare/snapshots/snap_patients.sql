{% snapshot snap_patients %}

{{
    config(
        target_schema='snapshots',
        unique_key='patient_id',
        strategy='timestamp',
        updated_at='updated_at'
    )
}}

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
    updated_at
FROM {{ ref('stg_patients') }}

{% endsnapshot %}