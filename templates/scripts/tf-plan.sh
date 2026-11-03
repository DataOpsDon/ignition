#!/usr/bin/bash
set -e

#
# Shell Script
# - Terraform Plan
#
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
TFVARS_FILE="$TFVARS_DIR/tfvars/$ENVIRONMENT.tfvars"

PLAN_FILE="${PIPELINE_ENVIRONMENT}-plan"

echo "==> Switching directories..."
cd "$TF_WORKSPACE"

echo "==> Using tfvars file: $TFVARS_FILE"
if echo "$TF_WORKSPACE" | grep -q "fwrules"; then
  echo "==> Detected 'fwrules' in workspace, running additional command..."
  terraform plan -var-file="$TFVARS_FILE" -out="$PLAN_FILE" -var-file="$TFVARS_DIR/tfvars/application-rules.tfvars" -var-file="$TFVARS_DIR/tfvars/network-rules.tfvars" -out="$PLAN_FILE" -input=false
else
  terraform plan -var-file="$TFVARS_FILE" -out="$PLAN_FILE" -input=false
fi

echo "==> Plan saved to: $PLAN_FILE"

# Human-readable copy of the plan (used for PR comments / job summaries).
terraform show -no-color "$PLAN_FILE" > "${PLAN_FILE}.txt"
echo "==> Plan text saved to: ${PLAN_FILE}.txt"
