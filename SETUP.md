# AKS Infrastructure Setup Guide

This guide walks you through deploying the AKS cluster infrastructure using GitHub Actions.

## Prerequisites

Before deploying, you need to set up the following Azure resources and GitHub secrets.

---

## Step 1: Azure Prerequisites

### 1.1 Create Resource Group for Terraform State

```powershell
# Login to Azure
az login

# Set your subscription
az account set --subscription "3d3eb4bd-5545-4196-b236-48a3af7a1b3f"

# Create resource group for IaC state storage
az group create --name iac --location uksouth
```

### 1.2 Create Storage Account for Terraform State

```powershell
# Create storage account (name must be globally unique, 3-24 lowercase letters/numbers)
az storage account create \
  --name stiacstatedev \
  --resource-group iac \
  --location uksouth \
  --sku Standard_LRS \
  --encryption-services blob

# Create container for tfstate files
az storage container create \
  --name tfstate \
  --account-name stiacstatedev

# Get the storage account access key (save this for STATE_ACCESS_KEY secret)
az storage account keys list \
  --resource-group iac \
  --account-name stiacstatedev \
  --query "[0].value" -o tsv
```

### 1.3 Create Service Principal for GitHub Actions

```powershell
# Create service principal with Contributor role on subscription
az ad sp create-for-rbac \
  --name "github-actions-aks" \
  --role "Contributor" \
  --scopes "/subscriptions/3d3eb4bd-5545-4196-b236-48a3af7a1b3f" \
  --sdk-auth

# Output will contain:
# {
#   "clientId": "YOUR_ARM_CLIENT_ID",
#   "clientSecret": "YOUR_ARM_CLIENT_SECRET",
#   "subscriptionId": "3d3eb4bd-5545-4196-b236-48a3af7a1b3f",
#   "tenantId": "YOUR_ARM_TENANT_ID",
#   ...
# }
```

### 1.4 Grant Storage Blob Data Contributor Role

```powershell
# Get the service principal object ID
$spObjectId = az ad sp list --display-name "github-actions-aks" --query "[0].id" -o tsv

# Assign Storage Blob Data Contributor for tfstate access
az role assignment create \
  --assignee $spObjectId \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/3d3eb4bd-5545-4196-b236-48a3af7a1b3f/resourceGroups/iac/providers/Microsoft.Storage/storageAccounts/stiacstatedev"
```

---

## Step 2: GitHub Secrets Configuration

Go to your repository: https://github.com/ShannonNaidoo01/aks/settings/secrets/actions

Add the following secrets:

| Secret Name | Value | Description |
|------------|-------|-------------|
| `ARM_CLIENT_ID` | From service principal output | Azure AD App Client ID |
| `ARM_CLIENT_SECRET` | From service principal output | Azure AD App Client Secret |
| `ARM_SUBSCRIPTION_ID` | `3d3eb4bd-5545-4196-b236-48a3af7a1b3f` | Your Azure Subscription ID |
| `ARM_TENANT_ID` | From service principal output | Azure AD Tenant ID |
| `STATE_ACCESS_KEY` | From storage account keys | Storage Account Access Key |

---

## Step 3: GitHub Environments (Optional but Recommended)

For production deployments with approval gates, create environments:

Go to: https://github.com/ShannonNaidoo01/aks/settings/environments

Create these environments:

| Environment | Protection Rules |
|-------------|-----------------|
| `dev-apply` | None (auto-approve) |
| `staging-apply` | Required reviewers |
| `prod-apply` | Required reviewers |

---

## Step 4: Push Code to GitHub

```powershell
# Navigate to your repo
cd C:\newexchangerepo\aks

# Add all files
git add .

# Commit
git commit -m "feat: initial AKS infrastructure with CI/CD pipeline"

# Push to GitHub
git push -u origin main
```

---

## Step 5: Deploy Infrastructure

### Option A: Automatic (on push to main)

The workflow automatically runs on push to main branch:
1. Validates Terraform code
2. Runs security scan
3. Creates a plan for the `dev` environment

### Option B: Manual Deployment

1. Go to **Actions** tab: https://github.com/ShannonNaidoo01/aks/actions
2. Click **Infrastructure as Code** workflow
3. Click **Run workflow**
4. Select:
   - **Environment**: `dev`, `staging`, or `prod`
   - **Action**: `plan` (first) then `apply`
5. Click **Run workflow**

**Always run `plan` first to review changes before `apply`!**

---

## Workflow Overview

```
┌─────────────────┐
│    Validate     │  Format check, init, validate
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Security Scan  │  Checkov security policies
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│      Plan       │  terraform plan with tfvars
└────────┬────────┘
         │
         ▼ (manual approval required)
┌─────────────────┐
│     Apply       │  terraform apply
└─────────────────┘
```

---

## Directory Structure

```
aks/
├── .github/
│   └── workflows/
│       └── iac.yml          # CI/CD pipeline
├── environments/
│   ├── dev.tfvars           # Development config (smaller, cheaper)
│   ├── staging.tfvars       # Staging config (medium)
│   └── prod.tfvars          # Production config (HA, zones)
├── modules/                  # Terraform modules (to be added)
│   ├── azurerm-aks-tf/
│   ├── helm-postgres-tf/
│   └── helm-kafka-tf/
├── main.tf                   # Root module
├── variables.tf              # Input variables
├── outputs.tf                # Output values
├── providers.tf              # Provider configuration
└── SETUP.md                  # This file
```

---

## Troubleshooting

### "Backend initialization required"

Ensure:
1. Storage account `stiacstatedev` exists in resource group `iac`
2. `STATE_ACCESS_KEY` secret is set correctly
3. Container `tfstate` exists in the storage account

```powershell
az storage container list --account-name stiacstatedev --query "[].name"
```

### "Error: Insufficient permissions"

The service principal needs:
- `Contributor` role on the subscription
- `Storage Blob Data Contributor` on the state storage account

```powershell
az role assignment list --assignee <client-id> --output table
```

### "Module not found"

The modules referenced in `main.tf` need to exist. Create placeholder modules or update `main.tf` to remove module references until they're ready.

---

## Cost Estimation

| Environment | Monthly Est. Cost |
|-------------|-------------------|
| dev | ~$150-200 (single node pools) |
| staging | ~$400-600 (multi-zone, larger VMs) |
| prod | ~$800-1200 (HA, premium storage) |

*Costs vary based on actual usage and autoscaling.*

---

## Next Steps

1. Create the Terraform modules in `modules/` directory
2. Configure Azure AD groups for RBAC (`admin_group_object_ids`)
3. Enable private cluster for production (`private_cluster_enabled = true`)
4. Set up Infracost for cost estimation on PRs
