#!/bin/bash

# This is a shared script to package a service's deployment artifacts into a single archive.
# It combines the Terraform code and the Lambda deployment package.
# This script is intended to be called from within a specific service's directory.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
TERRAFORM_DIR="terraform"
SERVICE_NAME=$(basename "$PWD")
LAMBDA_ARCHIVE="${SERVICE_NAME}-lambda.zip"
STAGING_DIR="package_staging"
PACKAGE_ARCHIVE="${SERVICE_NAME}-package.zip"

echo "--- Starting packaging for ${SERVICE_NAME} ---"

# 1. Validate that the required artifacts exist
if [ ! -d "$TERRAFORM_DIR" ]; then
  echo "Error: Missing required artifact '$TERRAFORM_DIR'. Ensure the '$TERRAFORM_DIR' directory exists."
  echo "Hint: You may need to run the build.sh script first to create '$LAMBDA_ARCHIVE'."
  exit 1
fi

# 2. Clean up previous packaging artifacts
echo "Cleaning up old packaging artifacts..."
if [ -f "$PACKAGE_ARCHIVE" ]; then
  rm -f "$PACKAGE_ARCHIVE"
fi
if [ -d "$STAGING_DIR" ]; then
  rm -rf "$STAGING_DIR"
fi

# 3. Create a staging directory and copy artifacts
echo "Staging artifacts for packaging..."
mkdir -p "$STAGING_DIR"
cp -r "$TERRAFORM_DIR" "$STAGING_DIR"/
if [ -d "alembic" ]; then
  cp -r "alembic" "$STAGING_DIR"/
fi
if [ -f "alembic.ini" ]; then
  cp "alembic.ini" "$STAGING_DIR"/
fi
if [ -f "$LAMBDA_ARCHIVE" ]; then
  cp "$LAMBDA_ARCHIVE" "$STAGING_DIR"/
fi

# 4. Create the final package archive
echo "Creating final package: '$PACKAGE_ARCHIVE'..."
(
  cd "$STAGING_DIR"
  zip -r "../$PACKAGE_ARCHIVE" .
)

# 5. Clean up the staging directory
rm -rf "$STAGING_DIR"

echo "--- Packaging successful. Final artifact created at '$PACKAGE_ARCHIVE' ---"