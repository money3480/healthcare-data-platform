{{ config(materialized='table') }}

SELECT
    p.insurance_type,
    c.diagnosis_code,
    DATE_TRUNC('month', c.claim_date)       AS claim_month,
    COUNT(*)                                AS total_claims,
    SUM(c.claim_amount)                     AS total_amount,
    AVG(c.claim_amount)                     AS avg_claim_amount,
    MEDIAN(c.claim_amount)                  AS median_claim_amount,
    SUM(CASE WHEN c.is_emergency
             THEN 1 ELSE 0 END)             AS emergency_claims,
    AVG(c.days_in_hospital)                 AS avg_days_in_hospital,
    SUM(CASE WHEN c.claim_status = 'denied'
             THEN 1 ELSE 0 END)             AS denied_claims,
    ROUND(
        SUM(CASE WHEN c.claim_status = 'denied' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0) * 100, 2)     AS denial_rate_pct
FROM {{ ref('fct_claims') }} c
JOIN {{ ref('dim_patients') }} p
    ON c.patient_id = p.patient_id
GROUP BY 1, 2, 3
