# Bootstrap Command Documentation

## 📋 Table of Contents

- [Overview](#overview)
- [ Install Ignition](#install-ignition)
- [⚙️ Configuration Reference (`config.yaml`)](#configuration-reference)
- [📝 Required Inputs Checklist](#required-inputs-checklist)
- [📍🔐 Where & What, Terraform State & UMIs](#Where-What-Terraform-State-UMIs)
   - [Where State Storage & Identity is Located](#umi-state-storage-location)
- [ ⛳ What Gets Created](#what-gets-created)
   - [In Azure](#in-azure)
   - [In Azure DevOps](#-in-azure-devops)

---

<a id="overview"></a>
## Overview

The `ign bootstrap` command sets up foundational Azure infrastructure required for Terraform remote state management, User Managed Identities (UMIs), and CI/CD operations (Azure DevOps / GitHub Actions).  
This is done on a environment by environment basis.  
Currently this bootstrapper does not store a statefile of the bootstrapping process.  

Command's we will use are:
- `ign bootstrap --plan-only` (to create a plan)
- `ign bootstrap --apply` (to apply the changes)

---

Steps are as follows:  
1. Instal `Ignition`
2. ADO `Prerequisites`
3. Adjust `config.yaml`  
4. Run `ign bootstrap --plan-only`  
5. Confirm you're happy with the plan and run `ign bootstrap --apply`  

---

<a id="install-ignition"></a>
1. ## 🧰 Install Ignition

### Recommended: Using uv (Fast & Modern) ⚡
```powershell
# Install uv if you don't have it
# Windows: powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

# Download and install the CLI
gh release download v{Release-Version} --repo telefonicatechuki/devops-cli --pattern "*.whl"
uv tool install ign-{Release-Version}-py3-none-any.whl --force

# Verify installation
ign --help
```

### Alternative: Using pip
```powershell
# Download and install
gh release download v{Release-Version} --repo telefonicatechuki/devops-cli --pattern "*.whl"
pip install ign-{Release-Version}-py3-none-any.whl
```

### Prerequisites

- GitHub CLI: Required for downloading from private repo

   ```powershell
   winget install GitHub.cli
   gh auth login
   ```

- uv (Recommended): Fast Python package installer

   ```powershell
   powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
   ```

### Usage

```powershell
ign --help
ign init
ign add-stack
```

### VS Code MCP Server (GitHub Copilot integration)
After installing, register the MCP server in VS Code with a single command:
```powershell
ign mcp install
```
This writes the server entry to your VS Code user settings so the `ign` MCP server
is available in every project. Pass `--workspace` to scope it to the current project
only, or `--copilot` to also register it in GitHub Copilot CLI.

```powershell
ign mcp install --workspace   # writes .vscode/mcp.json
ign mcp install --copilot     # also adds to ~/.copilot/mcp.json
```
Reload VS Code (Ctrl+Shift+P → "Developer: Reload Window") after running the command.

### Updating to Latest Version
```powershell
# With uv (recommended)
gh release download v{Release-Version} --repo telefonicatechuki/devops-cli --pattern "*.whl"
ign-{Release-Version}-py3-none-any.whl --force

# With pip
pip install --force-reinstall ign-{Release-Version}-py3-none-any.whl
```

---
2. ##  ADO Prerequisites
The user who's PAT code will be used to config the ADO project needs the following permissions.
 - Be a project admin of the project being configured
 - Be made an administrator of the Environments area within the project
---

<a id="configuration-reference"></a>
3. ## ⚙️ Configuration Reference (`config.yaml`)

Your `config.yaml` file defines all variables for bootstrapping. Fields marked with `<Fill Me In>` must be updated prior to running `ign bootstrap`.

---

<a id="required-inputs-checklist"></a>
## 📝 Required Inputs Checklist

Before running `ign bootstrap --apply`, you'll populate these fields in `config.yaml` everything else can be adjust or follow the default standard:

| Variable | Description | Example / Instructions |
|----------|-------------|------------------------|
| `isFirstTimeDeployToADO` | RUN ONCE: Deploys ADO permissions / variable group environments. Set to false after first run | true / false |
| `app_short` | Application short code | `app1`, `dlz`, `data` |
| `subscriptionId_State` | Azure Subscription ID for State Storage | `00000000-0000-0000-0000-000000000000` |
| `containers_state` | State storage containers for stacks you are planning on building | Configure container names under `containers_state` (e.g. `network`, `infra`) |
| `subscriptionId_umi` | Azure Subscription ID for User Managed Identities | `00000000-0000-0000-0000-000000000000` |
| `subscriptionId_Application` | Azure Subscription ID for target workload deployments | `00000000-0000-0000-0000-000000000000` |
| `subscriptionName_Application` | Azure Subscription Name for target workload deployments | `Application1-Dev` |
| `adoOrgUrl` | Azure DevOps Organization URL | `https://dev.azure.com/my-org/` |
| `adoProjectName` | Azure DevOps Project Name | Landing Zone |

---

<a id="Where-What-Terraform-State-UMIs"></a>
## 📍🔐 Where & What, Terraform State & UMIs

<a id="umi-state-storage-location"></a>
### Where State Storage & Identity is Located

**Terraform state is stored in an Azure Storage Account**, and deployment identities are created as **User Managed Identities (UMIs)** with Federated Identity Credentials / Azure DevOps Service Connections.

<a id="what-gets-created"></a>
## What Gets Created

<a id="in-azure"></a>
### ☁️ In Azure
When you run `ign bootstrap --apply`, the following resources are created in Azure based on your `config.yaml`:

1. **Resource Group for State Storage**
   - **Default Naming Template**: `rg-tfstate-${app_short}-${environment}-${locationShort}-${instance}`
   - **Example**: `rg-tfstate-app1-dev-uks-01`
   - **Subscription**: `subscriptionId_State`

2. **Storage Account for State Files**
   - **Default Naming Template**: `sttfstate${app_short}${environment}${locationShort}`
   - **Example**: `sttfstateapp1devuks`
   - **SKU**: Configurable via `stateStorageSku` (Default: `Standard_ZRS`)
   - **Public Access**: Configurable via `stateStoragePublic_network_access_enabled` (Default: `true`)
   - **Containers**: Dynamically created based on `containers_state` (e.g., `network`, `infra`)

3. **Resource Group for Managed Identities**
   - **Default Naming Template**: `rg-umi-${app_short}-${environment}-${locationShort}-${instance}`
   - **Subscription**: `subscriptionId_umi`

4. **User Managed Identities (UMI)**
   - **Build UMI**: `umi-tfbuild-${app_short}-${environment}-${locationShort}`
   - **Deploy UMI**: `umi-tfdeploy-${app_short}-${environment}-${locationShort}`

<a id="umi-role-assignments-and-permissions"></a>
### What User Managed Identity (UMI) Role Assignments & Permissions

The bootstrap process provisions two User Managed Identities (UMIs) with the following RBAC role assignments:

| UMI Example Name | RBAC Role | Resource / Scope |
|------------------|-----------|------------------|
| `umi-tfbuild-edp-dev-uks` | `Reader` | State Resource Group (`rg-tfstate-edp-dev-uks-01`) |
| `umi-tfbuild-edp-dev-uks` | `Storage Blob Data Contributor` | State Storage Account (`sttfstateedpdevuks`) |
| `umi-tfbuild-edp-dev-uks` | `Reader` | Application Subscription (`subscriptionId_Application`) |
| `umi-tfdeploy-edp-dev-uks` | `Owner` | State Resource Group (`rg-tfstate-edp-dev-uks-01`) |
| `umi-tfdeploy-edp-dev-uks` | `Storage Blob Data Contributor` | State Storage Account (`sttfstateedpdevuks`) |
| `umi-tfdeploy-edp-dev-uks` | `Owner` | Application Subscription (`subscriptionId_Application`) |

<a id="in-azure-devops"></a>
### 🐙 In GitHub Actions (`cicdPlatform: github`)
When `config.yaml` has `cicdPlatform: "github"` (set automatically by `ign init --cicd github`),
no Azure DevOps resources are created. Instead, bootstrap adds **OIDC federated credentials**
to the two managed identities so the repo's GitHub Actions workflows can log in to Azure:

| Identity | Federated credential subject | Used by |
|---|---|---|
| Build UMI | `repo:<orgName_gh>/<repositoryName_gh>:environment:<environmentName_gh>` | CI + plan jobs |
| Deploy UMI | `repo:<orgName_gh>/<repositoryName_gh>:environment:<environmentName_gh>/apply` | apply job |

Required keys: `orgName_gh`, `repositoryName_gh`, and `environmentName_gh` (defaults to
`environment`; must match the `environment` input in the stack workflows, e.g. `dev`, `prd`).
Run bootstrap once per environment (change `environment` and re-run).

After `ign bootstrap --apply`, open `bootstrap/BOOTSTRAP-OUTPUTS-<env>.md` and run the printed
`gh` commands to create the `<env>` and `<env>/apply` GitHub environments and set the
`AZURE_*` / `TF_STATE_*` variables. Add required reviewers to `<env>/apply`.

### 🚀 In Azure DevOps
When you run `ign bootstrap --apply`, the following resources are created in Azure DevOps based on your `config.yaml`:

1. **A private ADO project**
   - Git version control
   - Agile work item template
   - ADO features enabled
      - Boards
      - Repositories
      - Pipelines
      - Test Plans
      - Artifacts

2. **Project Permission Groups** - With appropriate permissions assigned
   - **Platform Admin**: Configurable via `createPlatformAdminGroup` (Default: `true`)
   - **Lead Engineers**: Configurable via `createLeadEngineerGroup` (Default: `true`)
   - **Engineers**: Configurable via `createEngineerGroup` (Default: `true`)
   - **Lead Testers**: Configurable via `createLeadTesterGroup` (Default: `true`)
   - **Testers**: Configurable via `createTesterGroup` (Default: `true`)
   - **Project Manager**: Configurable via `createPlatformAdminGroup` (Default: `true`)

3. **Permissions Assigned**
   - **Project Group:**
      

      **For Platform Admin**

      | Permission | Assigned |
      | ----- | ---- |
      | GENERIC_READ                 | Allow |
      | GENERIC_WRITE                | Allow |
      | DELETE                       | Deny |
      | PUBLISH_TEST_RESULTS         | Allow |
      | ADMINISTER_BUILD             | Allow |
      | START_BUILD                  | Allow |
      | EDIT_BUILD_STATUS            | Allow |
      | UPDATE_BUILD                 | Allow |
      | DELETE_TEST_RESULTS          | Allow |
      | VIEW_TEST_RESULTS            | Allow |
      | MANAGE_TEST_ENVIRONMENTS     | Allow |
      | MANAGE_TEST_CONFIGURATIONS   | Allow |
      | WORK_ITEM_DELETE             | Allow |
      | WORK_ITEM_MOVE               | Allow |
      | WORK_ITEM_PERMANENTLY_DELETE | Allow |
      | RENAME                       | Allow |
      | MANAGE_PROPERTIES            | Allow |
      | BYPASS_RULES                 | Deny |
      | SUPPRESS_NOTIFICATIONS       | Allow |
      | UPDATE_VISIBILITY            | Allow |
      | CHANGE_PROCESS               | Allow |
      | AGILETOOLS_PLANS             | Allow |


      **For Lead Engineers**

      | Permission | Assigned |
      | ----- | ---- |
      | GENERIC_READ                 | Allow |
      | GENERIC_WRITE                | Deny |
      | DELETE                       | Deny |
      | PUBLISH_TEST_RESULTS         | Allow |
      | ADMINISTER_BUILD             | Allow |
      | START_BUILD                  | Allow |
      | EDIT_BUILD_STATUS            | Allow |
      | UPDATE_BUILD                 | Allow |
      | DELETE_TEST_RESULTS          | Deny |
      | VIEW_TEST_RESULTS            | Allow |
      | MANAGE_TEST_ENVIRONMENTS     | Allow |
      | MANAGE_TEST_CONFIGURATIONS   | Allow |
      | WORK_ITEM_DELETE             | Allow |
      | WORK_ITEM_MOVE               | Allow |
      | WORK_ITEM_PERMANENTLY_DELETE | Deny |
      | RENAME                       | Deny |
      | MANAGE_PROPERTIES            | Allow |
      | BYPASS_RULES                 | Deny |
      | SUPPRESS_NOTIFICATIONS       | Allow |
      | UPDATE_VISIBILITY            | Allow |
      | CHANGE_PROCESS               | Deny |
      | AGILETOOLS_PLANS             | Allow |


      **For Engineers**

      | Permission | Assigned |
      | ----- | ---- |
      | GENERIC_READ                 | Allow |
      | GENERIC_WRITE                | Deny |
      | DELETE                       | Deny |
      | PUBLISH_TEST_RESULTS         | Allow |
      | ADMINISTER_BUILD             | Allow |
      | START_BUILD                  | Allow |
      | EDIT_BUILD_STATUS            | Allow |
      | UPDATE_BUILD                 | Allow |
      | DELETE_TEST_RESULTS          | Deny |
      | VIEW_TEST_RESULTS            | Allow |
      | MANAGE_TEST_ENVIRONMENTS     | Allow |
      | MANAGE_TEST_CONFIGURATIONS   | Allow |
      | WORK_ITEM_DELETE             | Allow |
      | WORK_ITEM_MOVE               | Allow |
      | WORK_ITEM_PERMANENTLY_DELETE | Deny |
      | RENAME                       | Deny |
      | MANAGE_PROPERTIES            | Allow |
      | BYPASS_RULES                 | Deny |
      | SUPPRESS_NOTIFICATIONS       | Allow |
      | UPDATE_VISIBILITY            | Allow |
      | CHANGE_PROCESS               | Deny |
      | AGILETOOLS_PLANS             | Allow |


      **For Lead Testers**

      | Permission | Assigned |
      | ----- | ---- |
      | GENERIC_READ                 | Allow |
      | GENERIC_WRITE                | Deny |
      | DELETE                       | Deny |
      | PUBLISH_TEST_RESULTS         | Allow |
      | ADMINISTER_BUILD             | Deny |
      | START_BUILD                  | Deny |
      | EDIT_BUILD_STATUS            | Deny |
      | UPDATE_BUILD                 | Deny |
      | DELETE_TEST_RESULTS          | Allow |
      | VIEW_TEST_RESULTS            | Allow |
      | MANAGE_TEST_ENVIRONMENTS     | Allow |
      | MANAGE_TEST_CONFIGURATIONS   | Allow |
      | WORK_ITEM_DELETE             | Allow |
      | WORK_ITEM_MOVE               | Allow |
      | WORK_ITEM_PERMANENTLY_DELETE | Deny |
      | RENAME                       | Deny |
      | MANAGE_PROPERTIES            | Allow |
      | BYPASS_RULES                 | Deny |
      | SUPPRESS_NOTIFICATIONS       | Allow |
      | UPDATE_VISIBILITY            | Allow |
      | CHANGE_PROCESS               | Deny |
      | AGILETOOLS_PLANS             | Allow |


      **For Testers**

      | Permission | Assigned |
      | ----- | ---- |
      | GENERIC_READ                 | Allow |
      | GENERIC_WRITE                | Deny |
      | DELETE                       | Deny |
      | PUBLISH_TEST_RESULTS         | Allow |
      | ADMINISTER_BUILD             | Deny |
      | START_BUILD                  | Deny |
      | EDIT_BUILD_STATUS            | Deny |
      | UPDATE_BUILD                 | Deny |
      | DELETE_TEST_RESULTS          | Allow |
      | VIEW_TEST_RESULTS            | Allow |
      | MANAGE_TEST_ENVIRONMENTS     | Allow |
      | MANAGE_TEST_CONFIGURATIONS   | Allow |
      | WORK_ITEM_DELETE             | Allow |
      | WORK_ITEM_MOVE               | Allow |
      | WORK_ITEM_PERMANENTLY_DELETE | Deny |
      | RENAME                       | Deny |
      | MANAGE_PROPERTIES            | Allow |
      | BYPASS_RULES                 | Deny |
      | SUPPRESS_NOTIFICATIONS       | Allow |
      | UPDATE_VISIBILITY            | Allow |
      | CHANGE_PROCESS               | Deny |
      | AGILETOOLS_PLANS             | Allow |


      **For Project Manager**

      | Permission | Assigned |
      | ----- | ---- |
      | GENERIC_READ                 | Allow |
      | GENERIC_WRITE                | Deny |
      | DELETE                       | Deny |
      | PUBLISH_TEST_RESULTS         | Deny |
      | ADMINISTER_BUILD             | Deny |
      | START_BUILD                  | Deny |
      | EDIT_BUILD_STATUS            | Deny |
      | UPDATE_BUILD                 | Deny |
      | DELETE_TEST_RESULTS          | Deny |
      | VIEW_TEST_RESULTS            | Allow |
      | MANAGE_TEST_ENVIRONMENTS     | Deny |
      | MANAGE_TEST_CONFIGURATIONS   | Deny |
      | WORK_ITEM_DELETE             | Allow |
      | WORK_ITEM_MOVE               | Allow |
      | WORK_ITEM_PERMANENTLY_DELETE | Deny |
      | RENAME                       | Deny |
      | MANAGE_PROPERTIES            | Deny |
      | BYPASS_RULES                 | Deny |
      | SUPPRESS_NOTIFICATIONS       | Allow |
      | UPDATE_VISIBILITY            | Allow |
      | CHANGE_PROCESS               | Deny |
      | AGILETOOLS_PLANS             | Allow |

   - **Iteration:**


      **For Platform Admin**

      | Permission | Assigned |
      | ----- | ---- |
      | GENERIC_READ    | Allow |
      | GENERIC_WRITE   | Allow |
      | CREATE_CHILDREN | Allow |
      | DELETE          | Allow |

      **For Lead Engineers**

      | Permission | Assigned |
      | ----- | ---- |
      | GENERIC_READ    | Allow |
      | GENERIC_WRITE   | Allow |
      | CREATE_CHILDREN | Allow |
      | DELETE          | Deny |


      **For Engineers**

      | Permission | Assigned |
      | ----- | ---- |
      | GENERIC_READ    | Allow |
      | GENERIC_WRITE   | Allow |
      | CREATE_CHILDREN | Deny |
      | DELETE          | Deny |


      **For Lead Testers**

      | Permission | Assigned |
      | ----- | ---- |
      | GENERIC_READ    | Allow |
      | GENERIC_WRITE   | Allow |
      | CREATE_CHILDREN | Allow |
      | DELETE          | Deny |


      **For Testers**

      | Permission | Assigned |
      | ----- | ---- |
      | GENERIC_READ    | Allow |
      | GENERIC_WRITE   | Allow |
      | CREATE_CHILDREN | Deny |
      | DELETE          | Deny |


      **For Project Manager**

      | Permission | Assigned |
      | ----- | ---- |
      | GENERIC_READ    | Allow |
      | GENERIC_WRITE   | Allow |
      | CREATE_CHILDREN | Allow |
      | DELETE          | Allow |

   - **Area:**


      **For Platform Admin**

      | Permission | Assigned |
      | ----- | ---- |
      | GENERIC_READ           | Allow |
      | GENERIC_WRITE          | Allow |
      | CREATE_CHILDREN        | Allow |
      | DELETE                 | Allow |
      | WORK_ITEM_READ         | Allow |
      | WORK_ITEM_WRITE        | Allow |
      | MANAGE_TEST_PLANS      | Allow |
      | MANAGE_TEST_SUITES     | Allow |
      | WORK_ITEM_SAVE_COMMENT | Allow |


      **For Lead Engineers**

      | Permission | Assigned |
      | ----- | ---- |
      | GENERIC_READ           | Allow |
      | GENERIC_WRITE          | Allow |
      | CREATE_CHILDREN        | Allow |
      | DELETE                 | Allow |
      | WORK_ITEM_READ         | Allow |
      | WORK_ITEM_WRITE        | Allow |
      | MANAGE_TEST_PLANS      | Allow |
      | MANAGE_TEST_SUITES     | Allow |
      | WORK_ITEM_SAVE_COMMENT | Allow |


      **For Engineers**

      | Permission | Assigned |
      | ----- | ---- |
      | GENERIC_READ           | Allow |
      | GENERIC_WRITE          | Allow |
      | CREATE_CHILDREN        | Deny |
      | DELETE                 | Deny |
      | WORK_ITEM_READ         | Allow |
      | WORK_ITEM_WRITE        | Allow |
      | MANAGE_TEST_PLANS      | Allow |
      | MANAGE_TEST_SUITES     | Allow |
      | WORK_ITEM_SAVE_COMMENT | Allow |


      **For Lead Testers**

      | Permission | Assigned |
      | ----- | ---- |
      | GENERIC_READ           | Allow |
      | GENERIC_WRITE          | Allow |
      | CREATE_CHILDREN        | Deny |
      | DELETE                 | Deny |
      | WORK_ITEM_READ         | Allow |
      | WORK_ITEM_WRITE        | Allow |
      | MANAGE_TEST_PLANS      | Allow |
      | MANAGE_TEST_SUITES     | Allow |
      | WORK_ITEM_SAVE_COMMENT | Allow |


      **For Testers**

      | Permission | Assigned |
      | ----- | ---- |
      | GENERIC_READ           | Allow |
      | GENERIC_WRITE          | Allow |
      | CREATE_CHILDREN        | Deny |
      | DELETE                 | Deny |
      | WORK_ITEM_READ         | Allow |
      | WORK_ITEM_WRITE        | Allow |
      | MANAGE_TEST_PLANS      | Allow |
      | MANAGE_TEST_SUITES     | Allow |
      | WORK_ITEM_SAVE_COMMENT | Allow |


      **For Project Manager**

      | Permission | Assigned |
      | ----- | ---- |
      | GENERIC_READ           | Allow |
      | GENERIC_WRITE          | Allow |
      | CREATE_CHILDREN        | Allow |
      | DELETE                 | Allow |
      | WORK_ITEM_READ         | Allow |
      | WORK_ITEM_WRITE        | Allow |
      | MANAGE_TEST_PLANS      | Deny |
      | MANAGE_TEST_SUITES     | Deny |
      | WORK_ITEM_SAVE_COMMENT | Allow |

   - **Service Connection:**


      **For Platform Admin**: Administrator

      **For Lead Engineers**: Administrator

      **For Engineers**: User

      **For Lead Testers**: Reader

      **For Testers**: Reader

      **For Project Manager**: Reader

   - **Repositories:**


      **For Platform Admin**

      | Permission | Assigned |
      | ----- | ---- |
      | Administer              | Allow |
      | GenericRead             | Allow |
      | GenericContribute       | Allow |
      | ForcePush               | Allow |
      | CreateBranch            | Allow |
      | CreateTag               | Allow |
      | ManageNote              | Allow |
      | PolicyExempt            | Deny |
      | CreateRepository        | Allow |
      | DeleteRepository        | Deny |
      | RenameRepository        | Allow |
      | EditPolicies            | Allow |
      | RemoveOthersLocks       | Allow |
      | ManagePermissions       | Allow |
      | PullRequestContribute   | Allow |
      | PullRequestBypassPolicy | Deny |


      **For Lead Engineers**

      | Permission | Assigned |
      | ----- | ---- |
      | Administer              | Deny |
      | GenericRead             | Allow |
      | GenericContribute       | Allow |
      | ForcePush               | Deny |
      | CreateBranch            | Allow |
      | CreateTag               | Allow |
      | ManageNote              | Allow |
      | PolicyExempt            | Deny |
      | CreateRepository        | Allow |
      | DeleteRepository        | Deny |
      | RenameRepository        | Allow |
      | EditPolicies            | Allow |
      | RemoveOthersLocks       | Allow |
      | ManagePermissions       | Allow |
      | PullRequestContribute   | Allow |
      | PullRequestBypassPolicy | Deny |


      **For Engineers**

      | Permission | Assigned |
      | ----- | ---- |
      | Administer              | Deny |
      | GenericRead             | Allow |
      | GenericContribute       | Allow |
      | ForcePush               | Deny |
      | CreateBranch            | Allow |
      | CreateTag               | Allow |
      | ManageNote              | Allow |
      | PolicyExempt            | Deny |
      | CreateRepository        | Deny |
      | DeleteRepository        | Deny |
      | RenameRepository        | Deny |
      | EditPolicies            | Deny |
      | RemoveOthersLocks       | Deny |
      | ManagePermissions       | Deny |
      | PullRequestContribute   | Allow |
      | PullRequestBypassPolicy | Deny |


      **For Lead Testers**

      | Permission | Assigned |
      | ----- | ---- |
      | Administer              | Deny |
      | GenericRead             | Allow |
      | GenericContribute       | Allow |
      | ForcePush               | Deny |
      | CreateBranch            | Allow |
      | CreateTag               | Allow |
      | ManageNote              | Allow |
      | PolicyExempt            | Deny |
      | CreateRepository        | Deny |
      | DeleteRepository        | Deny |
      | RenameRepository        | Deny |
      | EditPolicies            | Deny |
      | RemoveOthersLocks       | Deny |
      | ManagePermissions       | Deny |
      | PullRequestContribute   | Allow |
      | PullRequestBypassPolicy | Deny |


      **For Testers**

      | Permission | Assigned |
      | ----- | ---- |
      | Administer              | Deny |
      | GenericRead             | Allow |
      | GenericContribute       | Allow |
      | ForcePush               | Deny |
      | CreateBranch            | Allow |
      | CreateTag               | Allow |
      | ManageNote              | Allow |
      | PolicyExempt            | Deny |
      | CreateRepository        | Deny |
      | DeleteRepository        | Deny |
      | RenameRepository        | Deny |
      | EditPolicies            | Deny |
      | RemoveOthersLocks       | Deny |
      | ManagePermissions       | Deny |
      | PullRequestContribute   | Allow |
      | PullRequestBypassPolicy | Deny |


      **For Project Manager**

      | Permission | Assigned |
      | ----- | ---- |
      | Administer              | Deny |
      | GenericRead             | Allow |
      | GenericContribute       | Deny |
      | ForcePush               | Deny |
      | CreateBranch            | Deny |
      | CreateTag               | Deny |
      | ManageNote              | Deny |
      | PolicyExempt            | Deny |
      | CreateRepository        | Deny |
      | DeleteRepository        | Deny |
      | RenameRepository        | Deny |
      | EditPolicies            | Deny |
      | RemoveOthersLocks       | Deny |
      | ManagePermissions       | Deny |
      | PullRequestContribute   | Deny |
      | PullRequestBypassPolicy | Deny |

   - **Work item queries:**


      **For Platform Admin**

      | Permission | Assigned |
      | ----- | ---- |
      | Read              | Allow |
      | Delete            | Allow |
      | Contribute        | Allow |
      | ManagePermissions | Allow |


      **For Lead Engineers**

      | Permission | Assigned |
      | ----- | ---- |
      | Read              | Allow |
      | Delete            | Allow |
      | Contribute        | Allow |
      | ManagePermissions | Allow |

      **For Engineers**

      | Permission | Assigned |
      | ----- | ---- |
      | Read              | Allow |
      | Delete            | Allow |
      | Contribute        | Allow |
      | ManagePermissions | Deny |


      **For Lead Testers**

      | Permission | Assigned |
      | ----- | ---- |
      | Read              | Allow |
      | Delete            | Deny |
      | Contribute        | Allow |
      | ManagePermissions | Deny |


      **For Testers**

      | Permission | Assigned |
      | ----- | ---- |
      | Read              | Allow |
      | Delete            | Deny |
      | Contribute        | Allow |
      | ManagePermissions | Deny |


      **For Project Manager**

      | Permission | Assigned |
      | ----- | ---- |
      | Read              | Allow |
      | Delete            | Allow |
      | Contribute        | Allow |
      | ManagePermissions | Deny |

   - **Pipelines:**


      **For Platform Admin**

      | Permission | Assigned |
      | ----- | ---- |
      | ViewBuilds                     | Allow |
      | EditBuildQuality               | Allow |
      | RetainIndefinitely             | Allow |
      | DeleteBuilds                   | Allow |
      | ManageBuildQualities           | Allow |
      | DestroyBuilds                  | Allow |
      | UpdateBuildInformation         | Allow |
      | QueueBuilds                    | Allow |
      | ManageBuildQueue               | Allow |
      | StopBuilds                     | Allow |
      | ViewBuildDefinition            | Allow |
      | EditBuildDefinition            | Allow |
      | DeleteBuildDefinition          | Allow |
      | OverrideBuildCheckInValidation | Allow |
      | AdministerBuildPermissions     | Allow |
      | CreateBuildDefinition          | Allow |


      **For Lead Engineers**

      | Permission | Assigned |
      | ----- | ---- |
      | ViewBuilds                     | Allow |
      | EditBuildQuality               | Allow |
      | RetainIndefinitely             | Allow |
      | DeleteBuilds                   | Allow |
      | ManageBuildQualities           | Allow |
      | DestroyBuilds                  | Allow |
      | UpdateBuildInformation         | Allow |
      | QueueBuilds                    | Allow |
      | ManageBuildQueue               | Allow |
      | StopBuilds                     | Allow |
      | ViewBuildDefinition            | Allow |
      | EditBuildDefinition            | Allow |
      | DeleteBuildDefinition          | Allow |
      | OverrideBuildCheckInValidation | Allow |
      | AdministerBuildPermissions     | Allow |
      | CreateBuildDefinition          | Allow |


      **For Engineers**

      | Permission | Assigned |
      | ----- | ---- |
      | ViewBuilds                     | Allow |
      | EditBuildQuality               | Allow |
      | RetainIndefinitely             | Allow |
      | DeleteBuilds                   | Deny |
      | ManageBuildQualities           | Allow |
      | DestroyBuilds                  | Allow |
      | UpdateBuildInformation         | Allow |
      | QueueBuilds                    | Allow |
      | ManageBuildQueue               | Allow |
      | StopBuilds                     | Allow |
      | ViewBuildDefinition            | Allow |
      | EditBuildDefinition            | Allow |
      | DeleteBuildDefinition          | Deny |
      | OverrideBuildCheckInValidation | Deny |
      | AdministerBuildPermissions     | Deny |
      | CreateBuildDefinition          | Allow |


      **For Lead Testers**

      | Permission | Assigned |
      | ----- | ---- |
      | ViewBuilds                     | Allow |
      | EditBuildQuality               | Deny |
      | RetainIndefinitely             | Deny |
      | DeleteBuilds                   | Deny |
      | ManageBuildQualities           | Deny |
      | DestroyBuilds                  | Deny |
      | UpdateBuildInformation         | Deny |
      | QueueBuilds                    | Deny |
      | ManageBuildQueue               | Deny |
      | StopBuilds                     | Deny |
      | ViewBuildDefinition            | Allow |
      | EditBuildDefinition            | Deny |
      | DeleteBuildDefinition          | Deny |
      | OverrideBuildCheckInValidation | Deny |
      | AdministerBuildPermissions     | Deny |
      | CreateBuildDefinition          | Deny |


      **For Testers**

      | Permission | Assigned |
      | ----- | ---- |
      | ViewBuilds                     | Allow |
      | EditBuildQuality               | Deny |
      | RetainIndefinitely             | Deny |
      | DeleteBuilds                   | Deny |
      | ManageBuildQualities           | Deny |
      | DestroyBuilds                  | Deny |
      | UpdateBuildInformation         | Deny |
      | QueueBuilds                    | Deny |
      | ManageBuildQueue               | Deny |
      | StopBuilds                     | Deny |
      | ViewBuildDefinition            | Allow |
      | EditBuildDefinition            | Deny |
      | DeleteBuildDefinition          | Deny |
      | OverrideBuildCheckInValidation | Deny |
      | AdministerBuildPermissions     | Deny |
      | CreateBuildDefinition          | Deny |


      **For Project Manager**

      | Permission | Assigned |
      | ----- | ---- |
      | ViewBuilds                     | Allow |
      | EditBuildQuality               | Deny |
      | RetainIndefinitely             | Deny |
      | DeleteBuilds                   | Deny |
      | ManageBuildQualities           | Deny |
      | DestroyBuilds                  | Deny |
      | UpdateBuildInformation         | Deny |
      | QueueBuilds                    | Deny |
      | ManageBuildQueue               | Deny |
      | StopBuilds                     | Deny |
      | ViewBuildDefinition            | Allow |
      | EditBuildDefinition            | Deny |
      | DeleteBuildDefinition          | Deny |
      | OverrideBuildCheckInValidation | Deny |
      | AdministerBuildPermissions     | Deny |
      | CreateBuildDefinition          | Deny |

   - **Environments:**


      **For Platform Admin**: Administrator

      **For Lead Engineers**: Administrator

      **For Engineers**: User

      **For Lead Testers**: Reader

      **For Testers**: Reader

      **For Project Manager**: Reader

   - **Library:**


      **For Platform Admin**

      | Permission | Assigned |
      | ----- | ---- |
      | View        | Allow |
      | Create      | Allow |
      | Use         | Allow |
      | Administer  | Allow |
      | ViewSecrets | Allow |
      | Owner       | Allow |


      **For Lead Engineers**

      | Permission | Assigned |
      | ----- | ---- |
      | View        | Allow |
      | Create      | Allow |
      | Use         | Allow |
      | Administer  | Allow |
      | ViewSecrets | Allow |
      | Owner       | Allow |


      **For Engineers**

      | Permission | Assigned |
      | ----- | ---- |
      | View        | Allow |
      | Create      | Allow |
      | Use         | Allow |
      | Administer  | Deny |
      | ViewSecrets | Allow |
      | Owner       | Deny |


      **For Lead Testers**

      | Permission | Assigned |
      | ----- | ---- |
      | View        | Allow |
      | Create      | Deny |
      | Use         | Allow |
      | Administer  | Deny |
      | ViewSecrets | Allow |
      | Owner       | Deny |


      **For Testers**

      | Permission | Assigned |
      | ----- | ---- |
      | View        | Allow |
      | Create      | Deny |
      | Use         | Allow |
      | Administer  | Deny |
      | ViewSecrets | Allow |
      | Owner       | Deny |


      **For Project Manager**

      | Permission | Assigned |
      | ----- | ---- |
      | View        | Allow |
      | Create      | Deny |
      | Use         | Allow |
      | Administer  | Deny |
      | ViewSecrets | Deny |
      | Owner       | Deny |

   - **Tagging:**


      **For Platform Admin**

      | Permission | Assigned |
      | ----- | ---- |
      | Enumerate | Allow |
      | Create    | Allow |
      | Update    | Allow |
      | Delete    | Allow |


      **For Lead Engineers**

      | Permission | Assigned |
      | ----- | ---- |
      | Enumerate | Allow |
      | Create    | Allow |
      | Update    | Allow |
      | Delete    | Allow |


      **For Engineers**

      | Permission | Assigned |
      | ----- | ---- |
      | Enumerate | Allow |
      | Create    | Allow |
      | Update    | Allow |
      | Delete    | Allow |


      **For Lead Testers**

      | Permission | Assigned |
      | ----- | ---- |
      | Enumerate | Allow |
      | Create    | Allow |
      | Update    | Allow |
      | Delete    | Deny |


      **For Testers**

      | Permission | Assigned |
      | ----- | ---- |
      | Enumerate | Allow |
      | Create    | Allow |
      | Update    | Allow |
      | Delete    | Deny |


      **For Project Manager**

      | Permission | Assigned |
      | ----- | ---- |
      | Enumerate | Allow |
      | Create    | Allow |
      | Update    | Allow |
      | Delete    | Allow |



4. **Service Connections / CI/CD Credentials**
   - **Build SC**: `sc-build-${app_short}-${environment}-${locationShort}-${instance}`
   - **Deploy SC**: `sc-deploy-${app_short}-${environment}-${locationShort}-${instance}`

5. **Environmets**
   - Name = `${environment}`

6. **Library**
   - Name = `${environment}`

7. **Set Up Pipeline**
   - Once the bootstrap has been deployed to a file called BOOTSTRAP-OUTPUTS.${environment}.md will be created. This holds the following settigns which can be copied over to your pipeline.
      - **State Settings**
         - Subscription ID
         - Resource Group Name
         - Storage Account Name
         - Containers
      - **User Managed Identities for Build and Deply**
         - Name
         - Principal ID
         - Object ID / Client ID
      - **Service Connection**
         - Build Service Connection
         - Deploy Service Connection
