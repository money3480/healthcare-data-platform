import pandas as pd

def model(dbt, session):
    dbt.config(
        materialized="table",
        packages=["pandas", "scikit-learn"]
    )

    # Load upstream dbt models as Pandas DataFrames
    claims_df   = dbt.ref("fct_claims").to_pandas()
    patients_df = dbt.ref("dim_patients").to_pandas()

    # ── Feature engineering ───────────────────────────────────────
    features = claims_df.groupby("PATIENT_ID").agg(
        total_claims        = ("CLAIM_ID",          "count"),
        total_spend         = ("CLAIM_AMOUNT",       "sum"),
        avg_days_hospital   = ("DAYS_IN_HOSPITAL",   "mean"),
        emergency_count     = ("IS_EMERGENCY",       "sum"),
        denied_count        = ("CLAIM_STATUS",
                               lambda x: (x == "denied").sum()),
        unique_diagnoses    = ("DIAGNOSIS_CODE",     "nunique"),
    ).reset_index()

    features["avg_days_hospital"] = features["avg_days_hospital"].fillna(0)

    # ── Rule-based risk score (0–100) ─────────────────────────────
    # Each component is capped to prevent any single factor dominating
    features["risk_score"] = (
        (features["emergency_count"]  * 15).clip(0, 30) +
        (features["avg_days_hospital"] * 5).clip(0, 20) +
        (features["total_claims"]      * 0.5).clip(0, 20) +
        (features["unique_diagnoses"]  * 3).clip(0, 15) +
        (features["denied_count"]      * 5).clip(0, 15)
    ).clip(0, 100).round(1)

    # ── Risk category ─────────────────────────────────────────────
    features["risk_category"] = pd.cut(
        features["risk_score"],
        bins=[-1, 30, 60, 100],
        labels=["low", "medium", "high"]
    ).astype(str)

    features["scored_at"] = pd.Timestamp.utcnow()

    return features[[
        "PATIENT_ID",
        "total_claims",
        "total_spend",
        "avg_days_hospital",
        "emergency_count",
        "denied_count",
        "unique_diagnoses",
        "risk_score",
        "risk_category",
        "scored_at",
    ]]
