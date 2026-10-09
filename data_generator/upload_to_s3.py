"""
upload_to_s3.py
Uploads generated data files to S3 for Snowpipe ingestion.

Usage:
    # Upload all four initial data files
    uv run python data_generator/upload_to_s3.py

    # Upload files listed in a manifest file (one filename per line)
    uv run python data_generator/upload_to_s3.py --files data_generator/upload_manifest.txt

    # Upload specific files directly on the command line
    uv run python data_generator/upload_to_s3.py patients_update.csv providers_update.csv

Manifest file format (data_generator/upload_manifest.txt):
    patients_update.csv
    providers_update.csv

    Lines starting with # are ignored. Blank lines are ignored.

Environment variables required (set via . .\\set-env.ps1):
    S3_BUCKET             — your S3 bucket name
    AWS_ACCESS_KEY_ID     — AWS access key
    AWS_SECRET_ACCESS_KEY — AWS secret key
    AWS_DEFAULT_REGION    — e.g. us-east-1 (optional, defaults to us-east-1)
"""

import os
import sys
import boto3
from datetime import datetime, timezone


def read_manifest(path: str) -> list[str]:
    """Read a comma-separated manifest file and return a list of filenames.
    Each line can contain one or more comma-separated filenames.
    Lines starting with # are ignored. Blank lines are ignored.
    """
    if not os.path.exists(path):
        raise FileNotFoundError(f"Manifest file not found: {path}")
    files = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            files.extend(name.strip() for name in line.split(",") if name.strip())
    return files

DATA_DIR  = os.path.join(os.path.dirname(__file__), "data")
S3_BUCKET = os.environ["S3_BUCKET"]
REGION    = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")

s3 = boto3.client(
    "s3",
    region_name           = REGION,
    aws_access_key_id     = os.environ["AWS_ACCESS_KEY_ID"],
    aws_secret_access_key = os.environ["AWS_SECRET_ACCESS_KEY"],
)

# Maps local filename -> S3 prefix
S3_PREFIX = {
    "providers":    "providers",
    "patients":     "patients",
    "claims":       "claims",
    "appointments": "appointments",
}

# Default files uploaded when no arguments are given
DEFAULT_FILES = [
    "providers.csv",
    "patients.csv",
    "claims.json",
    "appointments.csv",
]

def s3_key_for(filename: str, ts: str) -> str:
    """Derive the S3 key from a local filename.
    patients_update.csv  -> patients/patients_update_<ts>.csv
    patients.csv         -> patients/patients_<ts>.csv
    claims.json          -> claims/claims_<ts>.json
    """
    base, ext = os.path.splitext(filename)          # e.g. "patients_update", ".csv"
    # find the matching prefix by checking which key the base starts with
    prefix = next(
        (p for p in S3_PREFIX if base == p or base.startswith(p + "_")),
        base   # fallback: use the base name as prefix
    )
    folder = S3_PREFIX.get(prefix, prefix)
    return f"{folder}/{base}_{ts}{ext}"


if __name__ == "__main__":
    ts = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")

    # --files <manifest> → read from file
    # positional args    → use them directly
    # no args            → upload all defaults
    if len(sys.argv) == 3 and sys.argv[1] == "--files":
        files_to_upload = read_manifest(sys.argv[2])
        print(f"Using manifest: {sys.argv[2]} ({len(files_to_upload)} files)")
    elif len(sys.argv) > 1:
        files_to_upload = sys.argv[1:]
    else:
        files_to_upload = DEFAULT_FILES

    print(f"Uploading to s3://{S3_BUCKET}/")
    for filename in files_to_upload:
        local_path = os.path.join(DATA_DIR, filename)
        if not os.path.exists(local_path):
            print(f"  SKIP  {filename} — not found at {local_path}")
            continue
        key = s3_key_for(filename, ts)
        s3.upload_file(local_path, S3_BUCKET, key)
        print(f"  OK    {filename}  ->  s3://{S3_BUCKET}/{key}")

    print("Upload complete. Snowpipe will ingest within ~30 seconds.")
