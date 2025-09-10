import os
import shutil
import boto3
import zipfile
import io
from alembic.config import Config
from alembic import command

s3_client = boto3.client('s3')

def handler(event, context):
    """
    This Lambda handler downloads a service package from S3,
    unzips it, and runs alembic migrations found within.
    """
    s3_bucket = os.environ['S3_BUCKET']
    s3_key = event['s3_key']
    extract_dir = f"/tmp/migration_files/{s3_key.replace('/', '_')}"

    print(f"Downloading s3://{s3_bucket}/{s3_key}...")
    s3_object = s3_client.get_object(Bucket=s3_bucket, Key=s3_key)
    zip_content = s3_object['Body'].read()

    if os.path.exists(extract_dir):
        print(f"Removing existing extraction directory: {extract_dir}")
        shutil.rmtree(extract_dir)

    print(f"Creating directory: {extract_dir}")
    os.makedirs(extract_dir)

    print(f"Unzipping package to {extract_dir}...")
    with zipfile.ZipFile(io.BytesIO(zip_content)) as z:
        z.extractall(extract_dir)

    # --- Nested Unzip for Lambda Code ---
    lambda_zip_path = next((os.path.join(extract_dir, f) for f in os.listdir(extract_dir) if f.endswith("-lambda.zip")), None)
    if lambda_zip_path:
        print(f"Found nested lambda package at {lambda_zip_path}, extracting...")
        with zipfile.ZipFile(lambda_zip_path, 'r') as z:
            z.extractall(extract_dir)

    alembic_ini_path = os.path.join(extract_dir, "alembic.ini")
    if os.path.exists(alembic_ini_path):
        print("Found alembic.ini, running migrations...")
        alembic_cfg = Config(alembic_ini_path)
        alembic_cfg.set_main_option("script_location", os.path.join(extract_dir, "alembic"))
        command.upgrade(alembic_cfg, "head")
        print("Migrations completed successfully.")
    else:
        print("No alembic.ini found, skipping migrations.")

    print(f"Cleaning up extraction directory: {extract_dir}")
    shutil.rmtree(extract_dir)

    return {"status": "SUCCESS"}
