# ==============================================================================
# Core Infrastructure Stack (Environment Scope)
# ==============================================================================
# Deploys: AKS cluster, ingress-nginx, cert-manager, cluster-test, entra-groups
# State: core/{env}/terraform.tfstate
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"

  backend "azurerm" {
    resource_group_name = "iac"
    container_name      = "core"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.47.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.25.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
}

# ------------------------------------------------------------------------------
# Providers
# ------------------------------------------------------------------------------
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

provider "azuread" {}

provider "random" {}

provider "kubernetes" {
  host                   = try(module.azurerm-aks.kube_admin_config_host, null)
  client_certificate     = try(base64decode(module.azurerm-aks.kube_admin_config_client_certificate), null)
  client_key             = try(base64decode(module.azurerm-aks.kube_admin_config_client_key), null)
  cluster_ca_certificate = try(base64decode(module.azurerm-aks.kube_admin_config_cluster_ca_certificate), null)
}

provider "helm" {
  kubernetes = {
    host                   = try(module.azurerm-aks.kube_admin_config_host, null)
    client_certificate     = try(base64decode(module.azurerm-aks.kube_admin_config_client_certificate), null)
    client_key             = try(base64decode(module.azurerm-aks.kube_admin_config_client_key), null)
    cluster_ca_certificate = try(base64decode(module.azurerm-aks.kube_admin_config_cluster_ca_certificate), null)
  }
}

provider "kubectl" {
  host                   = try(module.azurerm-aks.kube_admin_config_host, null)
  client_certificate     = try(base64decode(module.azurerm-aks.kube_admin_config_client_certificate), null)
  client_key             = try(base64decode(module.azurerm-aks.kube_admin_config_client_key), null)
  cluster_ca_certificate = try(base64decode(module.azurerm-aks.kube_admin_config_cluster_ca_certificate), null)
  load_config_file       = false
}

# ------------------------------------------------------------------------------
# Local Values
# ------------------------------------------------------------------------------
locals {
  aks_cluster_name     = var.aks_cluster_name != "" ? var.aks_cluster_name : "${var.environment}-aks-cluster"
  resource_group_name  = "${var.environment}-aks-rg"
  storage_account_name = var.storage_account_name != "" ? var.storage_account_name : "st${var.environment}aks${random_string.storage_suffix.result}"
  key_vault_name       = var.key_vault_name != "" ? var.key_vault_name : "kv-${var.environment}-aks-${random_string.kv_suffix.result}"

  common_tags = merge(var.tags, {
    environment = var.environment
    managed_by  = "opentofu"
    stack       = "core"
  })
}

resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "random_string" "kv_suffix" {
  length  = 4
  special = false
  upper   = false
}

# ------------------------------------------------------------------------------
# AKS Cluster Module
# ------------------------------------------------------------------------------
module "azurerm-aks" {
  source = "../../modules/azurerm-aks-tf"

  resource_group_name = local.resource_group_name
  location            = var.location
  environment         = var.environment
  tags                = local.common_tags

  aks_cluster_name        = local.aks_cluster_name
  kubernetes_version      = var.kubernetes_version
  sku_tier                = var.aks_sku_tier
  private_cluster_enabled = var.private_cluster_enabled

  vnet_address_space        = var.vnet_address_space
  aks_subnet_address_prefix = var.aks_subnet_address_prefix
  service_cidr              = var.service_cidr
  dns_service_ip            = var.dns_service_ip

  system_node_pool = var.system_node_pool
  node_pools       = var.node_pools

  storage_account_name             = local.storage_account_name
  storage_account_tier             = var.storage_account_tier
  storage_account_replication_type = var.storage_account_replication_type
  storage_containers               = var.storage_containers

  key_vault_name = local.key_vault_name
  key_vault_sku  = var.key_vault_sku

  workload_identities = merge(var.workload_identities, (length(var.dns_zones) > 0 || length(var.existing_dns_zones) > 0) ? {
    cert-manager = {
      namespace       = "cert-manager"
      service_account = "cert-manager"
      description     = "Workload identity for cert-manager DNS-01 challenges"
    }
  } : {})

  admin_group_object_ids = var.admin_group_object_ids
  azure_rbac_enabled     = var.azure_rbac_enabled

  dns_zones          = var.dns_zones
  existing_dns_zones = var.existing_dns_zones
}

# ------------------------------------------------------------------------------
# NGINX Ingress Controller
# ------------------------------------------------------------------------------
module "ingress_nginx" {
  source = "../../modules/helm-ingress-nginx-tf"
  count  = var.enable_ingress_nginx ? 1 : 0

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  namespace              = var.ingress_nginx_namespace
  chart_version          = var.ingress_nginx_chart_version
  replica_count          = var.ingress_nginx_replica_count
  internal_load_balancer = var.ingress_nginx_internal_lb

  default_ssl_certificate_secret = var.ingress_nginx_default_ssl_secret

  tags = local.common_tags

  depends_on = [module.azurerm-aks]
}

# ------------------------------------------------------------------------------
# Cert-Manager
# ------------------------------------------------------------------------------
locals {
  has_dns_zones = length(var.dns_zones) > 0 || length(var.existing_dns_zones) > 0

  dns_zone_key = (
    length(keys(var.existing_dns_zones)) > 0 ? keys(var.existing_dns_zones)[0] :
    length(keys(var.dns_zones)) > 0 ? keys(var.dns_zones)[0] : ""
  )

  dns_zone_name = (
    length(var.existing_dns_zones) > 0 ? var.existing_dns_zones[local.dns_zone_key].name :
    length(var.dns_zones) > 0 ? var.dns_zones[local.dns_zone_key].name : ""
  )

  dns_zone_resource_group = (
    length(var.existing_dns_zones) > 0 ? var.existing_dns_zones[local.dns_zone_key].resource_group_name :
    local.resource_group_name
  )
}

module "cert_manager" {
  source = "../../modules/helm-cert-manager-tf"
  count  = var.enable_cert_manager ? 1 : 0

  letsencrypt_email          = var.letsencrypt_email
  ingress_class              = var.ingress_class
  create_self_signed_issuer  = var.cert_manager_self_signed_issuer
  create_letsencrypt_issuers = var.cert_manager_letsencrypt_issuers

  enable_dns01_solver           = local.has_dns_zones
  azure_dns_zone_name           = local.dns_zone_name
  azure_dns_zone_resource_group = local.dns_zone_resource_group
  azure_subscription_id         = module.azurerm-aks.subscription_id
  cert_manager_client_id        = local.has_dns_zones ? module.azurerm-aks.workload_identities["cert-manager"].client_id : ""

  wildcard_certificates = var.wildcard_certificates

  depends_on = [module.ingress_nginx, module.azurerm-aks]
}

# ------------------------------------------------------------------------------
# Cluster Test App
# ------------------------------------------------------------------------------
module "cluster_test" {
  source = "../../modules/k8s-cluster-test-tf"
  count  = var.enable_cluster_test ? 1 : 0

  providers = {
    kubernetes = kubernetes
  }

  environment = var.environment
  hostname    = var.cluster_test_hostname

  tags = local.common_tags

  depends_on = [module.ingress_nginx]
}

# ------------------------------------------------------------------------------
# Azure Entra Groups
# ------------------------------------------------------------------------------
module "entra_groups" {
  source = "../../modules/azuread-groups-tf"
  count  = var.enable_entra_groups ? 1 : 0

  groups                        = var.entra_groups
  existing_groups               = var.entra_existing_groups
  include_current_user_as_owner = var.entra_include_current_user_as_owner
}
