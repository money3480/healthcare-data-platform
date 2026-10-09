"""
generate_updates.py
Generates update files for a subset of existing patients and providers
to test SCD Type 2 snapshot behaviour.

Reads the existing data/patients.csv and data/providers.csv, modifies
a small number of records (bumping updated_at), and writes:
  data/patients_update.csv
  data/providers_update.csv

Upload these to S3 to simulate production record changes:
  aws s3 cp data_generator/data/patients_update.csv  s3://<BUCKET>/patients/patients_update.csv
  aws s3 cp data_generator/data/providers_update.csv s3://<BUCKET>/providers/providers_update.csv

Then re-run the snapshot:
  cd healthcare
  uv run dbt snapshot --profiles-dir _prod_profiles --target dev

Usage:
    uv run python data_generator/generate_updates.py
"""

import os
import pandas as pd
from datetime import datetime, timezone

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")

# ── How many records to update ────────────────────────────────
N_PATIENTS_TO_UPDATE  = 5
N_PROVIDERS_TO_UPDATE = 3


def update_patients(n: int) -> pd.DataFrame:
    path = os.path.join(DATA_DIR, "patients.csv")
    if not os.path.exists(path):
        raise FileNotFoundError(
            f"patients.csv not found at {path}. "
            "Run generate_data.py first."
        )

    df = pd.read_csv(path)
    sample = df.sample(n, random_state=99).copy()

    # Cycle insurance types to force a visible change
    insurance_cycle = {
        "Medicare":  "Medicaid",
        "Medicaid":  "Private",
        "Private":   "Uninsured",
        "Uninsured": "Medicare",
    }
    sample["insurance_type"] = sample["insurance_type"].map(
        lambda v: insurance_cycle.get(v, "Medicare")
    )
    sample["updated_at"] = datetime.now(timezone.utc).isoformat()

    print(f"  Updating {n} patients:")
    for _, row in sample.iterrows():
        print(f"    patient_id={row['patient_id']}  "
              f"insurance_type -> {row['insurance_type']}")

    return sample


def update_providers(n: int) -> pd.DataFrame:
    path = os.path.join(DATA_DIR, "providers.csv")
    if not os.path.exists(path):
        raise FileNotFoundError(
            f"providers.csv not found at {path}. "
            "Run generate_data.py first."
        )

    df = pd.read_csv(path)
    sample = df.sample(n, random_state=99).copy()

    # Flip is_active status
    sample["is_active"] = ~sample["is_active"].astype(bool)
    sample["updated_at"] = datetime.now(timezone.utc).isoformat()

    print(f"  Updating {n} providers:")
    for _, row in sample.iterrows():
        print(f"    provider_id={row['provider_id']}  "
              f"is_active -> {row['is_active']}")

    return sample


if __name__ == "__main__":
    print("Generating update files for SCD2 testing...")

    patients_update  = update_patients(N_PATIENTS_TO_UPDATE)
    providers_update = update_providers(N_PROVIDERS_TO_UPDATE)

    out_patients  = os.path.join(DATA_DIR, "patients_update.csv")
    out_providers = os.path.join(DATA_DIR, "providers_update.csv")

    patients_update.to_csv(out_patients,   index=False)
    providers_update.to_csv(out_providers, index=False)

    print(f"\n  Written: {out_patients}")
    print(f"  Written: {out_providers}")

    print("""
Next steps:
  1. Upload to S3 (triggers Snowpipe):
       aws s3 cp data_generator/data/patients_update.csv  s3://$env:S3_BUCKET/patients/patients_update.csv
       aws s3 cp data_generator/data/providers_update.csv s3://$env:S3_BUCKET/providers/providers_update.csv

  2. Wait ~30 seconds for Snowpipe to load, then verify:
       SELECT COUNT(*) FROM HEALTHCARE.RAW.RAW_PATIENTS;
       -- should be 1005 (1000 original + 5 updated rows)

  3. Re-run the snapshot:
       cd healthcare
       uv run dbt snapshot --profiles-dir _prod_profiles --target dev

  4. Validate SCD2 — each updated patient/provider should have 2 rows:
       SELECT patient_id, insurance_type, dbt_valid_from, dbt_valid_to
       FROM HEALTHCARE.SNAPSHOTS.SNAP_PATIENTS
       WHERE patient_id IN (<paste IDs from step above>)
       ORDER BY patient_id, dbt_valid_from;

  5. Rebuild dims to pick up the changes:
       cd ..
       .\\run.ps1
""")
