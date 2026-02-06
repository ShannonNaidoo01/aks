# -----------------------------------------------------------------------------
# PostgreSQL Server Stack (Environment Scope)
# -----------------------------------------------------------------------------
# Deploy one PostgreSQL server per environment.
# State: postgres-svr/{env}/terraform.tfstate
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  backend "azurerm" {
    resource_group_name = "iac"
    container_name      = "postgres-svr"
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
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.10.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
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

provider "helm" {
  kubernetes = {
    host                   = data.azurerm_kubernetes_cluster.aks.kube_admin_config[0].host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config[0].cluster_ca_certificate)
  }
}

provider "kubectl" {
  host                   = data.azurerm_kubernetes_cluster.aks.kube_admin_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_admin_config[0].cluster_ca_certificate)
  load_config_file       = false
}

# -----------------------------------------------------------------------------
# Data Sources - Reference existing AKS cluster
# -----------------------------------------------------------------------------
data "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  resource_group_name = var.aks_resource_group
}

# -----------------------------------------------------------------------------
# PostgreSQL Server Module
# -----------------------------------------------------------------------------
module "postgres_server" {
  source = "../../modules/helm-postgres-svr-tf"

  environment   = var.environment
  namespace     = var.namespace
  cluster_name  = var.cluster_name
  instances     = var.instances
  storage_size  = var.storage_size
  storage_class = var.storage_class

  # PostgreSQL Resources
  cpu_request    = var.cpu_request
  cpu_limit      = var.cpu_limit
  memory_request = var.memory_request
  memory_limit   = var.memory_limit

  # PostgreSQL parameters
  max_connections = var.max_connections
  shared_buffers  = var.shared_buffers

  # PgBouncer configuration
  pgbouncer_instances         = var.pgbouncer_instances
  pgbouncer_pool_mode         = var.pgbouncer_pool_mode
  pgbouncer_max_client_conn   = var.pgbouncer_max_client_conn
  pgbouncer_default_pool_size = var.pgbouncer_default_pool_size
  pgbouncer_enable_ro_pooler  = var.pgbouncer_enable_ro_pooler

  # Backups
  enable_backups  = var.enable_backups
  backup_bucket   = var.backup_bucket
  backup_endpoint = var.backup_endpoint

  # Monitoring
  enable_monitoring = var.enable_monitoring
}
