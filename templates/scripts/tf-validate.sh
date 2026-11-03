#!/usr/bin/bash
set -e

#
# Shell Script
# - Terraform Validate
#
# Expects `terraform init` to have been run in PIPELINE_WORKSPACE.
# Note: `terraform validate` does not accept -var-file; variable values are
# checked at plan time.
#
export TF_IN_AUTOMATION=true

TF_WORKSPACE="$PIPELINE_WORKSPACE"

echo "==> Switching directories..."
cd "$TF_WORKSPACE"

echo "==> Validating Terraform configuration..."
terraform validate
