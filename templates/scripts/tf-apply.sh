#!/bin/bash

# Exit on any error
set -e

TF_WORKSPACE="$PIPELINE_WORKSPACE"
ENVIRONMENT="$PIPELINE_ENVIRONMENT"
VARIABLES="$PIPELINE_VARIABLES"

# Support nested tfvars folder - defaults to workspace root for backward compatibility
# TFVARS_PATH can be set to a subfolder like "tfvars" for nested structure
if [ -n "$TFVARS_PATH" ]; then
  TFVARS_DIR="$TF_WORKSPACE/$TFVARS_PATH"
else
  TFVARS_DIR="$TF_WORKSPACE"
fi

echo "==> Switching directories to workspace: $TF_WORKSPACE"
cd "$TF_WORKSPACE" || exit

echo "==> Using tfvars directory: $TFVARS_DIR"

PLAN_FILE="${PIPELINE_ENVIRONMENT}-plan"
if [ ! -f "$PLAN_FILE" ]; then
    echo "Error: Plan file '$PLAN_FILE' not found in $TF_WORKSPACE"
    exit 1
fi

echo "==> Applying infrastructure from plan..."
# Apply the plan file directly. This is auto-approved by default for plan files.
terraform apply "$PLAN_FILE"
