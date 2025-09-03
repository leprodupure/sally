#!/bin/bash

# This script packages the service's deployment artifacts into a single archive.
# It combines the Terraform code and the Lambda deployment package (lambda.zip).

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
TERRAFORM_DIR="terraform"
LAMBDA_ARCHIVE="lambda.zip"
STAGING_DIR="package_staging"

# Get the service name from the parent directory name to use in the archive name.
SERVICE_NAME=$(basename "$(dirname "$(realpath "$0")")")
PACKAGE_ARCHIVE="${SERVICE_NAME}-package.zip"

echo "--- Starting packaging for ${SERVICE_NAME} ---"

# 1. Validate that the required artifacts exist
if [ ! -d "$TERRAFORM_DIR" ] || [ ! -f "$LAMBDA_ARCHIVE" ]; then
  echo "Error: Missing required artifacts. Ensure the '$TERRAFORM_DIR' directory and '$LAMBDA_ARCHIVE' file exist."
  echo "Hint: You may need to run the build.sh script first to create '$LAMBDA_ARCHIVE'."
  exit 1
fi

# 2. Clean up previous packaging artifacts
echo "Cleaning up old packaging artifacts..."
rm -f "$PACKAGE_ARCHIVE"
rm -rf "$STAGING_DIR"

# 3. Create a staging directory and copy artifacts
echo "Staging artifacts for packaging..."
mkdir -p "$STAGING_DIR"
cp -r "$TERRAFORM_DIR" "$STAGING_DIR"/
cp "$LAMBDA_ARCHIVE" "$STAGING_DIR"/

# 4. Create the final package archive
echo "Creating final package: '$PACKAGE_ARCHIVE'..."
(
  cd "$STAGING_DIR"
  zip -r "../$PACKAGE_ARCHIVE" .
)

# 5. Clean up the staging directory
rm -rf "$STAGING_DIR"

echo "--- Packaging successful. Final artifact created at '$PACKAGE_ARCHIVE' ---"