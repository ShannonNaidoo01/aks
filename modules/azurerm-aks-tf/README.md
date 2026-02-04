# Azure AKS Terraform Module

Production-ready Azure Kubernetes Service (AKS) module with Azure CNI, Managed Identities, Workload Identity, and multi-environment deployment support.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Monorepo Structure](#monorepo-structure)
- [CI/CD Pipeline](#cicd-pipeline)
- [Environment-Based Deployment](#environment-based-deployment)
- [State Management](#state-management)
- [Module Versioning](#module-versioning)
- [Resources Created](#resources-created)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Usage](#usage)
- [Quick Start](#quick-start)

---

## Overview

This module deploys a complete AKS infrastructure including:

- **AKS Cluster** with Azure CNI networking
- **System + Workload Node Pools** with autoscaling
- **User Assigned Managed Identity** for the control plane
- **Workload Identity** support for pod-level Azure authentication
- **Azure Key Vault** with secrets provider integration
- **Storage Account** for application data
- **Virtual Network** with dedicated AKS subnet

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Azure Subscription                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Resource Group: {env}-aks-rg                      │   │
│  │                                                                      │   │
│  │  ┌──────────────────────────────────────────────────────────────┐   │   │
│  │  │                 Virtual Network: {env}-aks-cluster-vnet       │   │   │
│  │  │                     Address Space: 10.0.0.0/16                │   │   │
│  │  │  ┌──────────────────────────────────────────────────────┐    │   │   │
│  │  │  │              AKS Subnet: 10.0.0.0/20                  │    │   │   │
│  │  │  │                                                       │    │   │   │
│  │  │  │  ┌─────────────────────────────────────────────────┐ │    │   │   │
│  │  │  │  │           AKS Cluster: {env}-aks-cluster        │ │    │   │   │
│  │  │  │  │                                                  │ │    │   │   │
│  │  │  │  │  ┌─────────────────┐  ┌─────────────────┐      │ │    │   │   │
│  │  │  │  │  │  System Pool    │  │  Workload Pool  │      │ │    │   │   │
│  │  │  │  │  │  Standard_D2s   │  │  Standard_D4s   │      │ │    │   │   │
│  │  │  │  │  │  2-3 nodes      │  │  1-5 nodes      │      │ │    │   │   │
│  │  │  │  │  └─────────────────┘  └─────────────────┘      │ │    │   │   │
│  │  │  │  │                                                  │ │    │   │   │
│  │  │  │  │  Features:                                       │ │    │   │   │
│  │  │  │  │  - Azure CNI                                     │ │    │   │   │
│  │  │  │  │  - Workload Identity                             │ │    │   │   │
│  │  │  │  │  - Key Vault CSI Driver                          │ │    │   │   │
│  │  │  │  │  - Azure AD RBAC                                 │ │    │   │   │
│  │  │  │  └─────────────────────────────────────────────────┘ │    │   │   │
│  │  │  └──────────────────────────────────────────────────────┘    │   │   │
│  │  └──────────────────────────────────────────────────────────────┘   │   │
│  │                                                                      │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │   │
│  │  │   Key Vault     │  │ Storage Account │  │ Managed Identity│     │   │
│  │  │ kv-{env}-aks-xx │  │ st{env}aksxxxx  │  │ {env}-aks-*     │     │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Monorepo Structure

```
tune-exchange-mono/
├── .github/
│   └── workflows/
│       └── iac.yml                    # IaC CI/CD pipeline
├── infra/
│   └── terraform/
│       ├── main.tf                    # Root module - orchestration
│       ├── variables.tf               # Input variables
│       ├── outputs.tf                 # Output values
│       ├── providers.tf               # Provider configuration
│       ├── environments/              # Environment-specific configs
│       │   ├── dev.tfvars             # Development variables
│       │   ├── stg.tfvars             # Staging variables (future)
│       │   └── prd.tfvars             # Production variables (future)
│       └── modules/
│           └── azurerm-aks-tf/        # THIS MODULE
│               ├── main.tf            # Resource definitions
│               ├── variables.tf       # Module inputs
│               ├── outputs.tf         # Module outputs
│               └── README.md          # This file
└── src/                               # Application code (separate CI)
```

**Key Design Principles:**

1. **Root Module Orchestration**: The root `main.tf` calls child modules and handles:
   - Environment-based naming (`{env}-aks-cluster`, `{env}-aks-rg`)
   - Random suffix generation for globally unique names
   - Common tag management

2. **Module Self-Containment**: Each module is independent and reusable
3. **Environment Isolation**: Separate tfvars files per environment
4. **State Separation**: Each environment has its own state file

---

## CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/iac.yml`) automates infrastructure deployment.

### Pipeline Jobs

| Job | Purpose | Triggers |
|-----|---------|----------|
| **setup** | Determine target environment from branch name | All triggers |
| **detect-changes** | Find changed modules for selective tagging | All triggers |
| **validate** | Format check (`tofu fmt`), init, validate | All triggers |
| **tag-modules** | Auto-version modules on push to `dev` | Push to `dev` only |
| **plan** | Generate execution plan | All triggers |
| **apply** | Apply infrastructure changes | `[tfapply]` in commit or manual |
| **quality-gate** | Verify all checks passed | Always |

### Pipeline Flow

```
┌─────────┐     ┌────────────────┐     ┌──────────┐
│  Push   │────▶│     setup      │────▶│ validate │
│ to dev  │     │ (determine env)│     │ (fmt/init│
└─────────┘     └────────────────┘     │ /validate│
                        │              └────┬─────┘
                        ▼                   │
                ┌───────────────┐           │
                │detect-changes │           │
                │(find modules) │           │
                └───────┬───────┘           │
                        │                   │
                        ▼                   ▼
                ┌───────────────┐     ┌──────────┐
                │  tag-modules  │     │   plan   │
                │(auto-version) │     │          │
                └───────────────┘     └────┬─────┘
                                           │
                        ┌──────────────────┘
                        ▼
         ┌─────────────────────────────┐
         │  [tfapply] in commit msg?   │
         └──────────────┬──────────────┘
                        │ Yes
                        ▼
                 ┌────────────┐
                 │   apply    │
                 └────────────┘
                        │
                        ▼
                ┌──────────────┐
                │ quality-gate │
                └──────────────┘
```

### Trigger Conditions

| Event | Branch | Action |
|-------|--------|--------|
| Push | `dev` | Plan + optional Apply + Tag modules |
| Push | `stg` | Plan + optional Apply |
| Push | `prd` | Plan + optional Apply |
| Pull Request | → `dev` | Plan only (comment on PR) |
| Manual | Any | Plan or Apply (selectable) |

---

## Environment-Based Deployment

### Branch → Environment Mapping

| Branch | Environment | AKS Cluster Name | Resource Group |
|--------|-------------|------------------|----------------|
| `dev` | Development | `dev-aks-cluster` | `dev-aks-rg` |
| `stg` | Staging | `stg-aks-cluster` | `stg-aks-rg` |
| `prd` | Production | `prd-aks-cluster` | `prd-aks-rg` |

### How It Works

1. **Push to `dev` branch** → Uses `environments/dev.tfvars`
2. **Push to `stg` branch** → Uses `environments/stg.tfvars`
3. **Push to `prd` branch** → Uses `environments/prd.tfvars`

The root `main.tf` generates names based on the `environment` variable:

```hcl
locals {
  aks_cluster_name    = "${var.environment}-aks-cluster"  # e.g., dev-aks-cluster
  resource_group_name = "${var.environment}-aks-rg"       # e.g., dev-aks-rg
}
```

### Deploy Commands

```bash
# Plan only (default) - just push to branch
git push origin dev

# Plan + Apply - include [tfapply] in commit message
git commit -m "feat: add new node pool [tfapply]"
git push origin dev

# Manual trigger via GitHub Actions UI
# Go to Actions → Infrastructure as Code → Run workflow
```

---

## State Management

### State File Structure

Each environment has isolated state stored in Azure Blob Storage:

| Environment | Storage Account | Container | State File |
|-------------|-----------------|-----------|------------|
| `dev` | `txstatedev` | `terraform` | `main-stack.tfstate` |
| `stg` | `txstatestg` | `terraform` | `main-stack.tfstate` |
| `prd` | `txstateprd` | `terraform` | `main-stack.tfstate` |

### Backend Configuration

The backend is initialized dynamically during CI/CD:

```bash
tofu init \
  -backend-config="resource_group_name=iac" \
  -backend-config="storage_account_name=txstate${ENV}" \
  -backend-config="container_name=terraform" \
  -backend-config="key=main-stack.tfstate"
```

### State Storage Prerequisites

Before first deployment, create state storage:

```bash
# Create resource group for state storage
az group create --name iac --location uksouth

# Create storage accounts for each environment
for env in dev stg prd; do
  az storage account create \
    --name "txstate${env}" \
    --resource-group iac \
    --location uksouth \
    --sku Standard_LRS \
    --encryption-services blob

  az storage container create \
    --name terraform \
    --account-name "txstate${env}"
done
```

---

## Module Versioning

### Automatic Versioning

Modules are automatically versioned on push to `dev` branch using git tags.

### Tag Format

```
infra/{module}/v{major}.{minor}.{patch}

Examples:
  infra/aks/v1.0.0
  infra/aks/v1.1.0
  infra/postgres/v2.0.0
```

### Version Bump Rules (Conventional Commits)

| Commit Prefix | Version Bump | Example |
|---------------|--------------|---------|
| `feat!:` or `BREAKING CHANGE` | Major | `feat!: change API` → v1.0.0 → v2.0.0 |
| `feat:` | Minor | `feat: add node pool` → v1.0.0 → v1.1.0 |
| `fix:` / `chore:` / other | Patch | `fix: correct CIDR` → v1.0.0 → v1.0.1 |

### Referencing Specific Versions

```hcl
# Use a specific tagged version
module "azurerm-aks" {
  source = "git::https://github.com/org/tune-exchange-mono.git//infra/terraform/modules/azurerm-aks-tf?ref=infra/aks/v1.2.0"
}

# Use latest from dev branch
module "azurerm-aks" {
  source = "git::https://github.com/org/tune-exchange-mono.git//infra/terraform/modules/azurerm-aks-tf?ref=dev"
}
```

---

## Resources Created

| Resource | Description |
|----------|-------------|
| `azurerm_resource_group` | Container for all AKS resources |
| `azurerm_virtual_network` | VNet for AKS with Azure CNI |
| `azurerm_subnet` | Dedicated subnet for AKS nodes |
| `azurerm_user_assigned_identity` | Control plane managed identity |
| `azurerm_kubernetes_cluster` | AKS cluster with system node pool |
| `azurerm_kubernetes_cluster_node_pool` | Additional workload node pools |
| `azurerm_storage_account` | Storage for application data |
| `azurerm_storage_container` | Blob containers |
| `azurerm_key_vault` | Secrets management |
| `azurerm_role_assignment` | RBAC for identities |
| `azurerm_federated_identity_credential` | Workload identity federation |
| `azurerm_key_vault_secret` | Store workload identity details |

---

## Inputs

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `resource_group_name` | `string` | Name of the resource group |
| `location` | `string` | Azure region |
| `environment` | `string` | Environment name (dev/stg/prd) |
| `aks_cluster_name` | `string` | Name of the AKS cluster |
| `kubernetes_version` | `string` | Kubernetes version |
| `vnet_address_space` | `list(string)` | VNet address space |
| `aks_subnet_address_prefix` | `string` | Subnet CIDR |
| `service_cidr` | `string` | Kubernetes service CIDR |
| `dns_service_ip` | `string` | DNS service IP |
| `storage_account_name` | `string` | Storage account name |
| `key_vault_name` | `string` | Key Vault name |

### Optional Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `sku_tier` | `string` | `"Free"` | AKS SKU tier (Free/Standard) |
| `private_cluster_enabled` | `bool` | `false` | Enable private cluster |
| `system_node_pool` | `object` | See below | System node pool config |
| `node_pools` | `map(object)` | `{}` | Additional node pools |
| `workload_identities` | `map(object)` | `{}` | Workload identities to create |
| `azure_rbac_enabled` | `bool` | `true` | Enable Azure RBAC |
| `admin_group_object_ids` | `list(string)` | `[]` | Admin AD group IDs |

### System Node Pool Defaults

```hcl
system_node_pool = {
  name                = "system"
  vm_size             = "Standard_D2s_v5"
  node_count          = 2
  min_count           = 2
  max_count           = 5
  os_disk_size_gb     = 50
  enable_auto_scaling = true
  zones               = ["1", "2", "3"]
}
```

---

## Outputs

| Name | Description |
|------|-------------|
| `aks_cluster_id` | AKS cluster resource ID |
| `aks_cluster_name` | AKS cluster name |
| `aks_cluster_fqdn` | AKS API server FQDN |
| `aks_oidc_issuer_url` | OIDC issuer URL for workload identity |
| `kube_config` | Kubeconfig (sensitive) |
| `resource_group_name` | Resource group name |
| `vnet_id` | Virtual network ID |
| `aks_subnet_id` | AKS subnet ID |
| `key_vault_id` | Key Vault resource ID |
| `key_vault_uri` | Key Vault URI |
| `storage_account_name` | Storage account name |
| `workload_identities` | Map of workload identity details |
| `node_pools` | Map of additional node pool details |

---

## Usage

### Basic Usage (in root module)

```hcl
module "azurerm-aks" {
  source = "./modules/azurerm-aks-tf"

  # General
  resource_group_name = "dev-aks-rg"
  location            = "uksouth"
  environment         = "dev"
  tags                = { environment = "dev" }

  # AKS
  aks_cluster_name   = "dev-aks-cluster"
  kubernetes_version = "1.29"

  # Network
  vnet_address_space        = ["10.0.0.0/16"]
  aks_subnet_address_prefix = "10.0.0.0/20"
  service_cidr              = "10.1.0.0/16"
  dns_service_ip            = "10.1.0.10"

  # Node Pools
  system_node_pool = { max_count = 3 }
  node_pools = {
    workload = {
      vm_size   = "Standard_D4s_v5"
      max_count = 5
    }
  }

  # Storage & Key Vault
  storage_account_name = "stdevaksxxx"
  key_vault_name       = "kv-dev-aks-xxx"
}
```

---

## Quick Start

### 1. Prerequisites

- Azure CLI installed and logged in
- GitHub repository with secrets configured
- State storage accounts created

### 2. Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `ARM_CLIENT_ID` | Azure Service Principal Client ID |
| `ARM_CLIENT_SECRET` | Azure Service Principal Secret |
| `ARM_SUBSCRIPTION_ID` | Azure Subscription ID |
| `ARM_TENANT_ID` | Azure AD Tenant ID |
| `STATE_ACCESS_KEY` | Storage account access key |

### 3. Deploy to Development

```bash
# Clone the repository
git clone https://github.com/org/tune-exchange-mono.git
cd tune-exchange-mono

# Make changes to infra/terraform/environments/dev.tfvars

# Commit and push to trigger plan
git checkout dev
git add .
git commit -m "feat: initial AKS deployment"
git push origin dev

# Review plan in GitHub Actions
# Then apply with:
git commit --allow-empty -m "chore: apply infrastructure [tfapply]"
git push origin dev
```

### 4. Connect to Cluster

```bash
# Get credentials
az aks get-credentials \
  --resource-group dev-aks-rg \
  --name dev-aks-cluster

# Verify connection
kubectl get nodes
```

---

## Cost Optimization Tips

1. **Use Free tier** for dev (`aks_sku_tier = "Free"`)
2. **Enable autoscaling** with appropriate min/max counts
3. **Use LRS replication** for dev storage
4. **Right-size VMs**: Start with D2s for system, D4s for workloads
5. **Use spot instances** for non-critical workloads (set `priority = "Spot"` in node_pools)

---

## Security Best Practices

1. **Azure RBAC** enabled by default
2. **Private cluster** option for production
3. **Workload Identity** instead of service principal keys
4. **Key Vault integration** for secrets
5. **Network policies** with Azure CNI
6. **Managed Identity** for control plane

---

## License

MIT
