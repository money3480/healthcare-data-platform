"""
generate_data.py
Generates realistic synthetic healthcare data using Faker.
No real patient data — safe for development and portfolio use.

Usage:
    uv run python data_generator/generate_data.py
"""

import os
import uuid
import random
import pandas as pd
from datetime import datetime, timedelta
from faker import Faker

fake = Faker()
random.seed(42)
Faker.seed(42)

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "data")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ── ICD-10 diagnosis codes (common conditions) ────────────────
DIAGNOSIS_CODES = [
    "I10",    # Hypertension
    "E11.9",  # Type 2 diabetes
    "J18.9",  # Pneumonia
    "M54.5",  # Low back pain
    "F32.9",  # Major depressive disorder
    "K21.0",  # GERD with oesophagitis
    "Z00.00", # General adult examination
    "N39.0",  # Urinary tract infection
    "I25.10", # Coronary artery disease
    "G43.909",# Migraine
    "J06.9",  # Upper respiratory infection
    "E78.5",  # Hyperlipidaemia
]

SPECIALTIES = [
    "General Practice", "Cardiology", "Oncology", "Neurology",
    "Orthopaedics", "Psychiatry", "Paediatrics", "Emergency Medicine",
    "Internal Medicine", "Radiology",
]

PROVIDER_TYPES   = ["Primary Care", "Specialist", "Emergency", "Urgent Care"]
INSURANCE_TYPES  = ["Medicare", "Medicaid", "Private", "Uninsured"]
CLAIM_STATUSES   = ["approved", "denied", "pending", "appealed"]
APPT_STATUSES    = ["scheduled", "completed", "cancelled", "no_show"]
APPT_TYPES       = ["routine", "follow_up", "urgent", "specialist_referral"]


def generate_providers(n: int = 50) -> pd.DataFrame:
    records = []
    for _ in range(n):
        records.append({
            "provider_id":   str(uuid.uuid4()),
            "provider_name": f"Dr. {fake.last_name()}, {fake.first_name()}",
            "specialty":     random.choice(SPECIALTIES),
            "provider_type": random.choice(PROVIDER_TYPES),
            "city":          fake.city(),
            "state":         fake.state_abbr(),
            "npi_number":    str(random.randint(1000000000, 9999999999)),
            "is_active":     random.choices([True, False], weights=[90, 10])[0],
            "updated_at":    datetime.utcnow().isoformat(),
        })
    return pd.DataFrame(records)


def generate_patients(providers_df: pd.DataFrame, n: int = 1000) -> pd.DataFrame:
    provider_ids = providers_df["provider_id"].tolist()
    records = []
    for _ in range(n):
        dob = fake.date_of_birth(minimum_age=18, maximum_age=90)
        records.append({
            "patient_id":           str(uuid.uuid4()),
            "first_name":           fake.first_name(),
            "last_name":            fake.last_name(),
            "date_of_birth":        dob.isoformat(),
            "gender":               random.choice(["M", "F", "Other"]),
            "address":              fake.address().replace("\n", ", "),
            "phone":                fake.phone_number(),
            "insurance_type":       random.choice(INSURANCE_TYPES),
            "primary_provider_id":  random.choice(provider_ids),
            "registration_date":    fake.date_between(
                                        start_date="-5y",
                                        end_date="today"
                                    ).isoformat(),
            "updated_at":           datetime.utcnow().isoformat(),
        })
    return pd.DataFrame(records)


def generate_claims(patients_df: pd.DataFrame,
                    providers_df: pd.DataFrame,
                    n: int = 5000) -> pd.DataFrame:
    provider_ids = providers_df["provider_id"].tolist()
    records = []
    for _ in range(n):
        patient     = patients_df.sample(1).iloc[0]
        claim_date  = fake.date_between(start_date="-2y", end_date="today")
        is_emergency = random.choices([True, False], weights=[15, 85])[0]
        records.append({
            "claim_id":          str(uuid.uuid4()),
            "patient_id":        patient["patient_id"],
            "provider_id":       random.choice(provider_ids),
            "diagnosis_code":    random.choice(DIAGNOSIS_CODES),
            "claim_amount":      round(
                                    random.uniform(50, 15000)
                                    if is_emergency
                                    else random.uniform(50, 3000),
                                    2
                                ),
            "claim_date":        claim_date.isoformat(),
            "claim_status":      random.choices(
                                    CLAIM_STATUSES,
                                    weights=[65, 15, 15, 5]
                                )[0],
            "is_emergency":      is_emergency,
            "days_in_hospital":  (
                                    random.randint(1, 14)
                                    if is_emergency
                                    else 0
                                ),
            "updated_at":        datetime.utcnow().isoformat(),
        })
    return pd.DataFrame(records)


def generate_appointments(patients_df: pd.DataFrame,
                          providers_df: pd.DataFrame,
                          n: int = 3000) -> pd.DataFrame:
    provider_ids = providers_df["provider_id"].tolist()
    records = []
    for _ in range(n):
        patient      = patients_df.sample(1).iloc[0]
        booked_date  = fake.date_between(start_date="-1y", end_date="today")
        wait_days    = random.randint(0, 60)
        scheduled_dt = datetime.combine(booked_date, datetime.min.time()) \
                       + timedelta(days=wait_days, hours=random.randint(8, 17))
        status       = random.choices(APPT_STATUSES, weights=[10, 65, 15, 10])[0]
        actual_start = (
            (scheduled_dt + timedelta(minutes=random.randint(-10, 30))).isoformat()
            if status == "completed" else None
        )
        records.append({
            "appointment_id":   str(uuid.uuid4()),
            "patient_id":       patient["patient_id"],
            "provider_id":      random.choice(provider_ids),
            "scheduled_at":     scheduled_dt.isoformat(),
            "actual_start_at":  actual_start,
            "status":           status,
            "appointment_type": random.choice(APPT_TYPES),
            "booked_date":      booked_date.isoformat(),
            "appointment_notes": (
                fake.sentence(nb_words=8) if random.random() > 0.6 else None
            ),
            "updated_at":       datetime.utcnow().isoformat(),
        })
    return pd.DataFrame(records)


if __name__ == "__main__":
    print("Generating synthetic healthcare data...")

    providers    = generate_providers(50)
    patients     = generate_patients(providers, 1000)
    claims       = generate_claims(patients, providers, 5000)
    appointments = generate_appointments(patients, providers, 3000)

    providers.to_csv(   f"{OUTPUT_DIR}/providers.csv",    index=False)
    patients.to_csv(    f"{OUTPUT_DIR}/patients.csv",     index=False)
    claims.to_json(     f"{OUTPUT_DIR}/claims.json",      orient="records", lines=True)
    appointments.to_csv(f"{OUTPUT_DIR}/appointments.csv", index=False)

    print(f"  providers:    {len(providers):>6,} rows  → data/providers.csv")
    print(f"  patients:     {len(patients):>6,} rows  → data/patients.csv")
    print(f"  claims:       {len(claims):>6,} rows  → data/claims.json")
    print(f"  appointments: {len(appointments):>6,} rows  → data/appointments.csv")
    print("Done.")
