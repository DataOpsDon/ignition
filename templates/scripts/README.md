# Script Templates

This directory contains shell script templates for various Azure DevOps and Terraform operations.

## Azure Pipeline Scripts

### `azp-backend.sh`
Creates or updates Azure backend storage for Terraform state management. Sets up:
- Resource Group
- Storage Account with blob retention policies
- Storage Container for Terraform state files

### `azp-spn-generator.sh`
Creates or updates Service Principal Names (SPNs) with certificate-based authentication:
- Creates Key Vault for certificate storage
- Generates 10 SPNs with Owner role assignments
- Stores certificates securely in Key Vault

## Terraform Operation Scripts

### `tf-apply.sh`
Applies Terraform infrastructure changes with retry logic:
- Supports multiple var-file configurations
- Automatic retry on failure (up to 5 attempts)
- Special handling for firewall rules workspace

### `tf-destroy.sh`
Destroys Terraform infrastructure:
- Handles management group hierarchy cleanup
- Recursive deletion up to 6 levels deep
- Fallback manual cleanup on failure

### `tf-fmt.sh`
Formats Terraform files:
- Checks formatting across all files
- Shows differences
- Recursive formatting

### `tf-init.sh`
Initializes Terraform workspace:
- Configures Azure backend storage
- Sets up remote state management
- Handles subscription and storage account configuration

### `tf-install.sh`
Installs Terraform binary:
- Downloads Terraform 1.12.2 for Linux AMD64
- Extracts and installs to `/usr/local/bin`
- Sets up executable in system PATH

### `tf-plan.sh`
Generates Terraform execution plan:
- Supports environment-specific var files
- Special handling for firewall rules configurations
- Outputs plan file for apply stage

## Usage

These templates can be copied and customized for your specific Azure DevOps pipelines and Terraform workflows.
