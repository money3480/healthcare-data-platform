{{ config(materialized='table') }}

SELECT
    pr.provider_id,
    pr.provider_name,
    pr.specialty,
    pr.provider_type,
    pr.city,
    pr.state,
    COUNT(DISTINCT c.patient_id)            AS unique_patients,
    COUNT(c.claim_id)                       AS total_claims,
    ROUND(AVG(c.claim_amount), 2)           AS avg_claim_amount,
    SUM(CASE WHEN c.is_emergency
             THEN 1 ELSE 0 END)             AS emergency_claims,
    ROUND(AVG(c.days_in_hospital), 2)       AS avg_length_of_stay,
    COUNT(a.appointment_id)                 AS total_appointments,
    ROUND(AVG(a.wait_days), 1)              AS avg_appointment_wait_days,
    SUM(CASE WHEN a.status = 'no_show'
             THEN 1 ELSE 0 END)             AS no_shows,
    ROUND(
        SUM(CASE WHEN a.status = 'no_show' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(a.appointment_id), 0) * 100, 2) AS no_show_rate_pct
FROM {{ ref('dim_providers') }} pr
LEFT JOIN {{ ref('fct_claims') }}       c  ON pr.provider_id = c.provider_id
LEFT JOIN {{ ref('fct_appointments') }} a  ON pr.provider_id = a.provider_id
GROUP BY 1, 2, 3, 4, 5, 6
