#!/usr/bin/bash
set -e

#
# Shell Script
# - Terraform Format
#
# Checks formatting in PIPELINE_WORKSPACE when set, otherwise in the current
# directory.
#

if [ -n "$PIPELINE_WORKSPACE" ]; then
  echo "==> Switching directories to: $PIPELINE_WORKSPACE"
  cd "$PIPELINE_WORKSPACE"
fi

echo "==> Formatting files..."
terraform fmt -diff -check -recursive
