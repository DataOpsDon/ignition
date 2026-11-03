#!/usr/bin/bash
set -e

#
# Shell Script
# - Terraform Create or Update Azure Backend Storage
#

echo "==> Setting active Subscription..."
az account set \
    --subscription "$SUBSCRIPTION_ID"

RSG_NAME="$DEFAULT_PREFIX"

# 1. Resource Group Check & Creation
echo "==> Checking if Resource Group '$RSG_NAME' exists..."
RSG_EXISTS=$(az group exists --name "$RSG_NAME" --out tsv 2>/dev/null || echo "false")

if [ "$RSG_EXISTS" = "true" ]; then
    echo "==> Resource Group '$RSG_NAME' already exists. Skipping creation."
else
    echo "==> Creating Resource Group '$RSG_NAME'..."
    az group create \
        --name "$RSG_NAME" \
        --location "$PRIMARY_LOCATION" \
        --query 'properties.provisioningState' \
        --tags Environment=Production ServiceName=TerraformState TechnicalContact=ITInfrastructure BusinessUnit=Group \
        --out tsv
fi

# Set STORAGE_ACCOUNT_RSG_NAME to an output variable for downstream consumption.
echo "##vso[task.setVariable variable=STORAGE_ACCOUNT_RSG_NAME;isOutput=true]$RSG_NAME"

# 2. Storage Account Check & Creation
echo "==> Checking if Storage Account '$SA_NAME' exists..."
SA_EXISTS=$(az storage account show --name "$SA_NAME" --resource-group "$RSG_NAME" --query "name" --out tsv 2>/dev/null || true)

if [ -n "$SA_EXISTS" ]; then
    echo "==> Storage Account '$SA_NAME' already exists. Skipping creation."
else
    echo "==> Creating Storage Account '$SA_NAME'..."
    az storage account create \
        --name "$SA_NAME" \
        --resource-group "$RSG_NAME" \
        --location "$PRIMARY_LOCATION" \
        --kind 'StorageV2' \
        --access-tier 'Hot' \
        --sku 'Standard_LRS' \
        --min-tls-version 'TLS1_2' \
        --query 'id' \
        --tags Environment=Production ServiceName=TerraformState TechnicalContact=ITInfrastructure BusinessUnit=Group \
        --out tsv

    echo "==> Updating Blob service properties..."
    az storage account blob-service-properties update \
        --account-name "$SA_NAME" \
        --resource-group "$RSG_NAME" \
        --enable-container-delete-retention true \
        --container-delete-retention-days 7
fi

# 3. Storage Container Check & Creation
echo "==> Checking if Storage Container '$SC_NAME' exists..."
SC_EXISTS=$(az storage container exists --name "$SC_NAME" --account-name "$SA_NAME" --auth-mode login --query 'exists' --out tsv 2>/dev/null || echo "false")

if [ "$SC_EXISTS" = "true" ]; then
    echo "==> Storage Container '$SC_NAME' already exists. Skipping creation."
else
    echo "==> Creating Storage Container '$SC_NAME'..."
    az storage container create \
        --name "$SC_NAME" \
        --account-name "$SA_NAME" \
        --query 'created' \
        --auth-mode login \
        --out tsv
fi

# Set STORAGE_CONTAINER_NAME to an output variable for downstream consumption.
echo "##vso[task.setVariable variable=STORAGE_CONTAINER_NAME;isOutput=true]$SC_NAME"

# 4. Optional Blob Check
TARGET_BLOB="${BLOB_NAME:-${KEY:-}}"
if [ -n "$TARGET_BLOB" ]; then
    echo "==> Checking if Blob '$TARGET_BLOB' exists in container '$SC_NAME'..."
    BLOB_EXISTS=$(az storage blob exists --name "$TARGET_BLOB" --container-name "$SC_NAME" --account-name "$SA_NAME" --auth-mode login --query 'exists' --out tsv 2>/dev/null || echo "false")
    if [ "$BLOB_EXISTS" = "true" ]; then
        echo "==> Blob '$TARGET_BLOB' already exists. Skipping."
    fi
fi
