#Requires -Version 7.0
<#
.SYNOPSIS
    Sets up GitHub Actions OIDC federation with Azure so workflows can log in
    without storing client secrets.

.DESCRIPTION
    Use this when you are NOT using `ign bootstrap` (which does the same thing
    in Terraform). For one GitHub environment it:

      1. Creates (or reuses) a resource group and two user-assigned managed
         identities: a build identity (plan) and a deploy identity (apply)
      2. Adds federated credentials trusting the repo's GitHub environments:
            build  -> repo:<org>/<repo>:environment:<Environment>
            deploy -> repo:<org>/<repo>:environment:<Environment>/apply
      3. Grants Reader (build) and Owner (deploy) on the target subscription,
         and Storage Blob Data Contributor on the state storage account
      4. Prints (or, with -SetGitHubVariables, runs) the `gh variable set`
         commands that configure the GitHub environments

    Requires the Azure CLI (logged in with rights to create identities and
    role assignments) and, for -SetGitHubVariables, the GitHub CLI.

.EXAMPLE
    ./scripts/setup-github-oidc.ps1 `
        -GitHubOrg my-org -GitHubRepo my-infra-repo -Environment dev `
        -SubscriptionId 00000000-0000-0000-0000-000000000000 `
        -IdentityResourceGroup rg-umi-myapp-dev-uks-01 -Location uksouth `
        -StateSubscriptionId 00000000-0000-0000-0000-000000000000 `
        -StateResourceGroup rg-tfstate-myapp-dev-uks-01 `
        -StateStorageAccount sttfstatemyappdevuks -StateContainer infra
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$GitHubOrg,
    [Parameter(Mandatory)] [string]$GitHubRepo,
    [Parameter(Mandatory)] [string]$Environment,
    [Parameter(Mandatory)] [string]$SubscriptionId,
    [Parameter(Mandatory)] [string]$IdentityResourceGroup,
    [string]$Location = "uksouth",
    [string]$BuildIdentityName = "umi-tfbuild-$GitHubRepo-$Environment",
    [string]$DeployIdentityName = "umi-tfdeploy-$GitHubRepo-$Environment",
    [Parameter(Mandatory)] [string]$StateSubscriptionId,
    [Parameter(Mandatory)] [string]$StateResourceGroup,
    [Parameter(Mandatory)] [string]$StateStorageAccount,
    [string]$StateContainer = "tfstate",
    [switch]$SetGitHubVariables
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ISSUER   = "https://token.actions.githubusercontent.com"
$AUDIENCE = "api://AzureADTokenExchange"

function Write-Step([string]$msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg)   { Write-Host "    [OK] $msg" -ForegroundColor Green }

function Invoke-Az {
    param([string[]]$Arguments)
    $output = az @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Azure CLI error ($LASTEXITCODE): $output" }
    if ($output) { return ($output | ConvertFrom-Json) }
}

Write-Step "Resolving tenant"
$account  = Invoke-Az @("account", "show", "--subscription", $SubscriptionId)
$TenantId = $account.tenantId
Write-Ok "Tenant: $TenantId"

Write-Step "Ensuring resource group $IdentityResourceGroup"
if ($PSCmdlet.ShouldProcess($IdentityResourceGroup, "Create resource group")) {
    Invoke-Az @("group", "create", "--subscription", $SubscriptionId, "--name", $IdentityResourceGroup, "--location", $Location) | Out-Null
}

function New-FederatedIdentity([string]$Name, [string]$Subject) {
    Write-Step "Ensuring managed identity $Name"
    $id = Invoke-Az @("identity", "create", "--subscription", $SubscriptionId,
        "--resource-group", $IdentityResourceGroup, "--name", $Name, "--location", $Location)
    Write-Ok "clientId: $($id.clientId)"

    $credName = ($Subject -replace '[^A-Za-z0-9-]', '-').Trim('-')
    if ($credName.Length -gt 120) { $credName = $credName.Substring(0, 120) }
    Write-Step "Adding federated credential ($Subject)"
    if ($PSCmdlet.ShouldProcess($Name, "Federated credential $Subject")) {
        $existing = Invoke-Az @("identity", "federated-credential", "list", "--subscription", $SubscriptionId,
            "--resource-group", $IdentityResourceGroup, "--identity-name", $Name)
        if ($existing | Where-Object { $_.subject -eq $Subject }) {
            Write-Ok "Already present"
        } else {
            Invoke-Az @("identity", "federated-credential", "create", "--subscription", $SubscriptionId,
                "--resource-group", $IdentityResourceGroup, "--identity-name", $Name,
                "--name", $credName, "--issuer", $ISSUER, "--subject", $Subject, "--audiences", $AUDIENCE) | Out-Null
            Write-Ok "Created"
        }
    }
    return $id
}

$build  = New-FederatedIdentity $BuildIdentityName  "repo:${GitHubOrg}/${GitHubRepo}:environment:${Environment}"
$deploy = New-FederatedIdentity $DeployIdentityName "repo:${GitHubOrg}/${GitHubRepo}:environment:${Environment}/apply"

Write-Step "Assigning roles"
$subScope = "/subscriptions/$SubscriptionId"
$saScope  = "/subscriptions/$StateSubscriptionId/resourceGroups/$StateResourceGroup/providers/Microsoft.Storage/storageAccounts/$StateStorageAccount"
$assignments = @(
    @{ Principal = $build.principalId;  Role = "Reader";                        Scope = $subScope },
    @{ Principal = $deploy.principalId; Role = "Owner";                         Scope = $subScope },
    @{ Principal = $build.principalId;  Role = "Storage Blob Data Contributor"; Scope = $saScope },
    @{ Principal = $deploy.principalId; Role = "Storage Blob Data Contributor"; Scope = $saScope }
)
foreach ($a in $assignments) {
    if ($PSCmdlet.ShouldProcess($a.Scope, "Assign $($a.Role)")) {
        Invoke-Az @("role", "assignment", "create", "--assignee-object-id", $a.Principal,
            "--assignee-principal-type", "ServicePrincipal", "--role", $a.Role, "--scope", $a.Scope) | Out-Null
        Write-Ok "$($a.Role) -> $($a.Scope)"
    }
}
Write-Host "    NOTE: Owner is granted unconstrained here. Prefer the conditional Owner assignment created by" -ForegroundColor Yellow
Write-Host "          'ign bootstrap', which blocks the deploy identity from granting privileged roles." -ForegroundColor Yellow

$repo = "$GitHubOrg/$GitHubRepo"
$commands = @()
foreach ($pair in @(@($Environment, $build.clientId), @("$Environment/apply", $deploy.clientId))) {
    $envName = $pair[0]; $clientId = $pair[1]
    $vars = [ordered]@{
        AZURE_CLIENT_ID          = $clientId
        AZURE_TENANT_ID          = $TenantId
        AZURE_SUBSCRIPTION_ID    = $SubscriptionId
        TF_STATE_SUBSCRIPTION_ID = $StateSubscriptionId
        TF_STATE_RESOURCE_GROUP  = $StateResourceGroup
        TF_STATE_STORAGE_ACCOUNT = $StateStorageAccount
        TF_STATE_CONTAINER       = $StateContainer
    }
    foreach ($k in $vars.Keys) {
        $commands += ,@("variable", "set", $k, "--env", $envName, "--body", $vars[$k], "--repo", $repo)
    }
}

if ($SetGitHubVariables) {
    Write-Step "Configuring GitHub environments (gh CLI)"
    foreach ($envName in @($Environment, "$Environment/apply")) {
        gh api --method PUT "repos/$repo/environments/$([uri]::EscapeDataString($envName))" | Out-Null
        Write-Ok "Environment $envName"
    }
    foreach ($c in $commands) { gh @c | Out-Null }
    Write-Ok "Variables set"
} else {
    Write-Step "Run these to configure the GitHub environments (or re-run with -SetGitHubVariables)"
    foreach ($c in $commands) { Write-Host ("gh " + (($c | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } }) -join ' ')) -ForegroundColor Yellow }
}

Write-Host "`nAdd required reviewers to the '$Environment/apply' environment to gate applies." -ForegroundColor White
