# -----------------------------------------------------------------------------
# PostgreSQL Database Stack (Application Scope)
# -----------------------------------------------------------------------------
# Create databases on the PostgreSQL server for individual applications.
# State: postgres-db/{env}/{app-name}/terraform.tfstate
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  backend "azurerm" {
    resource_group_name = "iac"
    container_name      = "postgres-db"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.25.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Providers
# -----------------------------------------------------------------------------
provider "azurerm" {
  features {}
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.aks.kube_admin_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config[0].cluster_ca_certificate)
}

provider "kubectl" {
  host                   = data.azurerm_kubernetes_cluster.aks.kube_admin_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config[0].cluster_ca_certificate)
  load_config_file       = false
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------
data "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  resource_group_name = var.aks_resource_group
}

data "azurerm_key_vault" "aks" {
  count               = var.key_vault_name != "" ? 1 : 0
  name                = var.key_vault_name
  resource_group_name = var.aks_resource_group
}

# -----------------------------------------------------------------------------
# PostgreSQL Database Module
# -----------------------------------------------------------------------------
module "postgres_database" {
  source = "../../modules/helm-postgres-db-tf"

  # PostgreSQL server reference
  postgres_namespace        = var.postgres_namespace
  postgres_host             = var.postgres_host         # Direct (for DDL)
  pgbouncer_host            = var.pgbouncer_host        # Pooled RW (primary)
  pgbouncer_host_ro         = var.pgbouncer_host_ro     # Pooled RO (replicas)
  postgres_superuser_secret = var.postgres_superuser_secret

  # Database configuration
  database_name = var.database_name
  database_user = var.database_user != "" ? var.database_user : var.database_name
  extensions    = var.extensions

  # Optional Key Vault integration
  key_vault_id = var.key_vault_name != "" ? data.azurerm_key_vault.aks[0].id : ""
}
