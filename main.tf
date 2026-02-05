# ------------------------------------------------------------------------------
# Terraform Remote Backend Configuration
# ------------------------------------------------------------------------------
# Backend is partially configured here. The following values are passed
# during `tofu init` via -backend-config flags:
#   - storage_account_name: Azure Storage Account for state
#   - container_name: Container within storage account
#   - key: Path to state file (environment/terraform.tfstate)
#   - access_key: Storage account access key (from STATE_ACCESS_KEY secret)
# ------------------------------------------------------------------------------
terraform {
  backend "azurerm" {
    resource_group_name = "iac"
  }
}

# ------------------------------------------------------------------------------
# Local values for naming conventions
# ------------------------------------------------------------------------------
locals {
  # Generate names based on environment if not explicitly provided
  aks_cluster_name     = var.aks_cluster_name != "" ? var.aks_cluster_name : "${var.environment}-aks-cluster"
  resource_group_name  = "${var.environment}-aks-rg"
  storage_account_name = var.storage_account_name != "" ? var.storage_account_name : "st${var.environment}aks${random_string.storage_suffix.result}"
  key_vault_name       = var.key_vault_name != "" ? var.key_vault_name : "kv-${var.environment}-aks-${random_string.kv_suffix.result}"

  # Common tags applied to all resources
  common_tags = merge(var.tags, {
    environment = var.environment
    managed_by  = "terraform"
  })
}

# Random suffix for globally unique storage account name
resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Random suffix for globally unique key vault name
resource "random_string" "kv_suffix" {
  length  = 4
  special = false
  upper   = false
}

# ------------------------------------------------------------------------------
# Call the Azure AKS module.
# ------------------------------------------------------------------------------
module "azurerm-aks" {
  source = "./modules/azurerm-aks-tf"

  # General
  resource_group_name = local.resource_group_name
  location            = var.location
  environment         = var.environment
  tags                = local.common_tags

  # AKS Cluster
  aks_cluster_name        = local.aks_cluster_name
  kubernetes_version      = var.kubernetes_version
  sku_tier                = var.aks_sku_tier
  private_cluster_enabled = var.private_cluster_enabled

  # Network (Azure CNI)
  vnet_address_space        = var.vnet_address_space
  aks_subnet_address_prefix = var.aks_subnet_address_prefix
  service_cidr              = var.service_cidr
  dns_service_ip            = var.dns_service_ip

  # Node Pools
  system_node_pool = var.system_node_pool
  node_pools       = var.node_pools

  # Storage Account
  storage_account_name             = local.storage_account_name
  storage_account_tier             = var.storage_account_tier
  storage_account_replication_type = var.storage_account_replication_type
  storage_containers               = var.storage_containers

  # Key Vault
  key_vault_name = local.key_vault_name
  key_vault_sku  = var.key_vault_sku

  # Workload Identities
  workload_identities = var.workload_identities

  # RBAC
  admin_group_object_ids = var.admin_group_object_ids
  azure_rbac_enabled     = var.azure_rbac_enabled
}

# ------------------------------------------------------------------------------
# Cert-Manager Module
# ------------------------------------------------------------------------------
module "cert_manager" {
  source = "./modules/helm-cert-manager-tf"
  count  = var.enable_cert_manager ? 1 : 0

  chart_version     = var.cert_manager_version
  letsencrypt_email = var.letsencrypt_email
  ingress_class     = "nginx"

  # Create issuers
  create_self_signed_issuer  = true
  create_letsencrypt_issuers = var.letsencrypt_email != ""

  depends_on = [module.azurerm-aks]
}

# ------------------------------------------------------------------------------
# Future modules (uncomment when ready)
# ------------------------------------------------------------------------------
# module "postgres" {
#   source = "./modules/helm-postgres-tf"
#   aks_cluster_name = local.aks_cluster_name
#   depends_on = [module.azurerm-aks]
# }

# module "kafka" {
#   source = "./modules/helm-kafka-tf"
#   aks_cluster_name = local.aks_cluster_name
#   depends_on = [module.azurerm-aks]
# }
