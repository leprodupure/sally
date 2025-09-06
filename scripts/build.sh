#!/bin/bash

# This is a shared script to prepare a Python service for packaging.
# It creates a clean, self-contained output directory with source code and dependencies.
# This script is intended to be called from within a specific service's directory.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
OUTPUT_DIR="dist"
SRC_DIR="src"
REQUIREMENTS_FILE="requirements.txt"
SERVICE_NAME=$(basename "$PWD")
ARCHIVE_NAME="${SERVICE_NAME}-lambda.zip"

echo "--- Starting build for ${SERVICE_NAME} ---"

echo "Checking that source directory exists..."
if [ ! -d "$SRC_DIR" ]; then
  echo "Source directory '$SRC_DIR' not found. Skipping this step."
  exit 0
fi

# 1. Clean up previous build artifacts
echo "Cleaning up old build artifacts..."
rm -rf "$OUTPUT_DIR"
rm -f "$ARCHIVE_NAME"

# 2. Create a fresh output directory and copy source
echo "Creating output directory and copying source..."
mkdir -p "$OUTPUT_DIR"
cp -r "$SRC_DIR"/* "$OUTPUT_DIR"/

# 3. Install production dependencies into the output directory
if [ -f "$REQUIREMENTS_FILE" ]; then
  echo "Installing dependencies from '$REQUIREMENTS_FILE' into '$OUTPUT_DIR'..."
  pip install --target "$OUTPUT_DIR" -r "$REQUIREMENTS_FILE"
else
  echo "No '$REQUIREMENTS_FILE' found. Skipping dependency installation."
fi

# 4. Create the zip archive
echo "Creating deployment archive: '$ARCHIVE_NAME'..."
(
  cd "$OUTPUT_DIR"
  zip -r "../$ARCHIVE_NAME" .
)

echo "--- Build successful. Deployment archive created at '$ARCHIVE_NAME' ---"