# edp Infrastructure

This repository contains Infrastructure as Code (IaC) for the edp project.

## Project Structure

```
.
├── stacks/              # Deployment stacks (dlz, dmz, unity-catalog, etc.)
├── .github/workflows/   # One caller workflow per stack
├── scripts/             # setup-github-oidc.ps1 (manual OIDC setup)
├── templates/           # Reusable templates and utilities
│   ├── scaffold/        # Stack scaffolding templates
│   ├── scripts/         # Terraform scripts called by the Makefile / pipelines
│   ├── utils/           # Terraform utility modules
│   └── tests/           # Testing configurations
└── Makefile            # Common operations
```

## Getting Started

### Prerequisites

- Azure CLI
- Terraform >= 1.5.0
- GitHub CLI (`gh`) and access to the GitHub organisation

### Adding a New Stack

Use the CLI to add a new deployment stack:

```bash
ign add-stack --stack-name <name>
```

### Manual Deployment

1. Navigate to the stack directory:
   ```bash
   cd stacks/<stack-name>/terraform
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Plan the deployment:
   ```bash
   terraform plan -var-file="tfvars/dev.tfvars"
   ```

4. Apply the changes:
   ```bash
   terraform apply -var-file="tfvars/dev.tfvars"
   ```

## CI/CD Pipelines

Each stack has a caller workflow in `.github/workflows/<stack>.yml` that uses the shared reusable pipeline in [`DataOpsDon/terraform-azure-cicd`](https://github.com/DataOpsDon/terraform-azure-cicd) (pinned to `main`):

- **CI**: `terraform init`, `fmt`, `validate` and a Checkov scan
- **Plan**: plan uploaded as an artifact and posted to the pull request
- **Apply**: applies the reviewed plan on `develop` (dev) / `main` (prd), gated by the `<env>/apply` GitHub environment
- **Auth**: OIDC federated credentials to Azure - no stored secrets
- **State**: Terraform state in Azure Storage (azurerm backend)

| Branch / event | Environment | Apply |
|---|---|---|
| `feature/**` push, PR into `develop` | `dev` | no |
| `develop` push | `dev` | yes |
| PR into `main` | `prd` | no |
| `main` push | `prd` | yes |

## Configuration

### Environment Variables

Each stack supports multiple environments:
- `dev` - Development
- `tst` - Test
- `uat` - User Acceptance Testing
- `prd` - Production

### GitHub Environments

Create the `dev`, `dev/apply`, `prd` and `prd/apply` environments and set the `AZURE_*` / `TF_STATE_*` variables on each. `ign bootstrap` prints the exact `gh variable set` commands; `scripts/setup-github-oidc.ps1` is an alternative if you are not using bootstrap. Add required reviewers to the `*/apply` environments.

## Contributing

1. Create a feature branch
2. Make your changes
3. Test locally
4. Submit a pull request

## Support

For questions or issues, contact the DevOps team.
