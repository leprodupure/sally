import os
import subprocess
import shutil
import boto3
import zipfile
import io

s3_client = boto3.client('s3')
def handler(event, context):
    """
    This Lambda handler downloads a service package from S3,
    unzips it, and runs alembic migrations found within.
    """
    s3_bucket = os.environ['S3_BUCKET']
    s3_key = event['s3_key']
    extract_dir = f"/tmp/migration_files/{s3_key}"

    print(f"Downloading s3://{s3_bucket}/{s3_key}...")
    s3_object = s3_client.get_object(Bucket=s3_bucket, Key=s3_key)
    print("Reading the zip file...")
    zip_content = s3_object['Body'].read()

    if os.path.exists(extract_dir):
        print(f"Removing the extraction directory {extract_dir} of a previous execution...")
        shutil.rmtree(extract_dir)

    print(f"Creating the folder {extract_dir}...")
    os.makedirs(extract_dir)

    print(f"Unzipping package to {extract_dir}...")
    with zipfile.ZipFile(io.BytesIO(zip_content)) as z:
        z.extractall(extract_dir)

    if os.path.exists(os.path.join(extract_dir, "alembic.ini")):
        print("Found alembic.ini, running migrations...")
        # The env.py script will use the same environment variables as the app to connect
        subprocess.check_call(["alembic", "upgrade", "head"], cwd=extract_dir)
        print("Migrations completed successfully.")

        print(f"Cleaning the extraction directory {extract_dir} ...")
        shutil.rmtree(extract_dir)
    else:
        print("No alembic.ini found, skipping migrations.")

    return {"status": "SUCCESS"}