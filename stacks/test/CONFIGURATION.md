# Configuration Guide - test

This document lists all files that need to be updated with your specific configuration values before deploying this stack.

## ⚠️ Required Updates

Before deploying this stack, you must update the following files with your Azure subscription IDs and other configuration values:

### 1. GitHub Actions (`.github/workflows/test.yml`)

The workflow calls the shared reusable pipeline `DataOpsDon/terraform-azure-cicd` pinned to `main`. Pin it to a release tag (or full commit SHA) before going live.

Identity and Terraform state settings are read from **GitHub environment variables**. Create these environments in the repository (Settings → Environments) and set the variables on each:

| Environment | Used by | `AZURE_CLIENT_ID` |
|---|---|---|
| `dev`, `prd` | CI + plan jobs | build identity client ID |
| `dev/apply`, `prd/apply` | apply job (add required reviewers) | deploy identity client ID |

Variables required on every environment:

- **`AZURE_CLIENT_ID`**: client ID of the managed identity (see table above)
- **`AZURE_TENANT_ID`**: Microsoft Entra tenant ID
- **`AZURE_SUBSCRIPTION_ID`**: subscription this stack deploys into
- **`TF_STATE_SUBSCRIPTION_ID`**: subscription holding the Terraform state storage account
- **`TF_STATE_RESOURCE_GROUP`**: resource group of the state storage account
- **`TF_STATE_STORAGE_ACCOUNT`**: state storage account name
- **`TF_STATE_CONTAINER`**: state blob container

The state blob key defaults to `stacks/test/terraform/<environment>.tfstate`.

`ign bootstrap --apply` writes `bootstrap/BOOTSTRAP-OUTPUTS-<env>.md` containing the exact `gh variable set` commands. Without bootstrap, use `scripts/setup-github-oidc.ps1`.

Optional repository secret **`MODULE_REPO_PAT`**: read token for private Terraform module repositories.

### 2. Terraform Variable Files (`terraform/tfvars/*.tfvars`)

Update the following `.tfvars` files with your subscription IDs:

- **`terraform/tfvars/dev.tfvars`**
  - Update `subscription_id` with your DEV environment subscription ID
  - Update `management_subscription_id` if applicable

- **`terraform/tfvars/prd.tfvars`**
  - Update `subscription_id` with your PRD environment subscription ID
  - Update `management_subscription_id` if applicable

- **`terraform/tfvars/terraform.tfvars`**
  - Common variables shared across all environments

- **`terraform/tfvars/tst.tfvars`**
  - Update `subscription_id` with your TST environment subscription ID
  - Update `management_subscription_id` if applicable

- **`terraform/tfvars/uat.tfvars`**
  - Update `subscription_id` with your UAT environment subscription ID
  - Update `management_subscription_id` if applicable

- **`terraform/tfvars/uks.tfvars`**
  - Location-specific variables for UK South

- **`terraform/tfvars/ukw.tfvars`**
  - Location-specific variables for UK West

Example for environment-specific files (e.g., `dev.tfvars`):
```hcl
subscription_id            = "your-subscription-id-here"
management_subscription_id = "your-management-subscription-id-here"
location                   = "uksouth"
environment                = "dev"
```

## 📝 Additional Configuration

You may also need to update:

- **Workflow**: Review `.github/workflows/test.yml` - branch triggers, environments (add `tst`/`uat` jobs if needed) and the pinned CI/CD ref
- **Resource Names**: Review and customize resource names in `terraform/main.tf` if needed
- **Variables**: Review `terraform/variables.tf` for any additional variables that need values

## ✅ Verification

After updating the configuration files:

1. Verify all subscription IDs are correct
2. Ensure state backend configuration points to the correct storage account
3. Review environment-specific values in `.tfvars` files
4. Test with `terraform plan` before applying changes

## 📚 Resources

- [Azure Subscription IDs](https://docs.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id)
- [Terraform State Backend](https://www.terraform.io/docs/language/settings/backends/azurerm.html)
