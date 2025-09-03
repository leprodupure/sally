#!/bin/bash

# This script prepares the service for packaging by creating a clean, self-contained output directory.
# It copies the application source code, installs all Python dependencies, and creates a zip archive.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
OUTPUT_DIR="dist"
SRC_DIR="src"
REQUIREMENTS_FILE="requirements.txt"
# Get the service name from the parent directory name to use in the archive name.
SERVICE_NAME=$(basename "$(dirname "$(realpath "$0")")")
ARCHIVE_NAME="${SERVICE_NAME}-lambda.zip"

echo "--- Starting build for ${SERVICE_NAME} ---"

# 1. Clean up the previous build directory
echo "Cleaning up old build artifacts from '$OUTPUT_DIR'..."
rm -rf "$OUTPUT_DIR"
rm -f "$ARCHIVE_NAME"

# 2. Create a fresh output directory
echo "Creating output directory: '$OUTPUT_DIR'"
mkdir -p "$OUTPUT_DIR"

# 3. Copy the application source code
echo "Copying source code from '$SRC_DIR' to '$OUTPUT_DIR'..."
cp -r "$SRC_DIR"/* "$OUTPUT_DIR"/

# 4. Install production dependencies into the output directory
echo "Installing dependencies from '$REQUIREMENTS_FILE' into '$OUTPUT_DIR'..."
pip install --target "$OUTPUT_DIR" -r "$REQUIREMENTS_FILE"

# 5. Create the zip archive
echo "Creating deployment archive: '$ARCHIVE_NAME'..."
(
  cd "$OUTPUT_DIR"
  zip -r "../$ARCHIVE_NAME" .
)

echo "--- Build successful. Deployment archive created at '$ARCHIVE_NAME' ---"