"""
upload_to_s3.py
Uploads generated data files to S3 for Snowpipe ingestion.

Usage:
    uv run python data_generator/upload_to_s3.py

Environment variables required:
    S3_BUCKET           — your S3 bucket name
    AWS_ACCESS_KEY_ID   — AWS access key
    AWS_SECRET_ACCESS_KEY — AWS secret key
    AWS_DEFAULT_REGION  — e.g. us-east-1 (optional, defaults to us-east-1)
"""

import os
import boto3
from datetime import datetime, timezone

DATA_DIR  = os.path.join(os.path.dirname(__file__), "data")
S3_BUCKET = os.environ["S3_BUCKET"]
REGION    = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")

s3 = boto3.client(
    "s3",
    region_name          = REGION,
    aws_access_key_id    = os.environ["AWS_ACCESS_KEY_ID"],
    aws_secret_access_key= os.environ["AWS_SECRET_ACCESS_KEY"],
)

# Timestamp suffix so each upload creates a new file (Snowpipe won't re-load)
ts = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")

FILES = [
    ("providers.csv",    f"providers/providers_{ts}.csv"),
    ("patients.csv",     f"patients/patients_{ts}.csv"),
    ("claims.json",      f"claims/claims_{ts}.json"),
    ("appointments.csv", f"appointments/appointments_{ts}.csv"),
]

if __name__ == "__main__":
    print(f"Uploading to s3://{S3_BUCKET}/")
    for local_name, s3_key in FILES:
        local_path = os.path.join(DATA_DIR, local_name)
        if not os.path.exists(local_path):
            print(f"  SKIP  {local_name} — not found (run generate_data.py first)")
            continue
        s3.upload_file(local_path, S3_BUCKET, s3_key)
        print(f"  OK    {local_name}  ->  s3://{S3_BUCKET}/{s3_key}")
    print("Upload complete. Snowpipe will ingest within ~2 minutes.")
