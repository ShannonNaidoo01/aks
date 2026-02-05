# -----------------------------------------------------------------------------
# Resource Group Outputs
# -----------------------------------------------------------------------------

output "resource_group_id" {
  description = "The ID of the AKS resource group"
  value       = module.azurerm-aks.resource_group_id
}

output "resource_group_name" {
  description = "The name of the AKS resource group"
  value       = module.azurerm-aks.resource_group_name
}

output "resource_group_location" {
  description = "The location of the AKS resource group"
  value       = module.azurerm-aks.resource_group_location
}

# -----------------------------------------------------------------------------
# Network Outputs
# -----------------------------------------------------------------------------

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = module.azurerm-aks.vnet_id
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = module.azurerm-aks.vnet_name
}

output "aks_subnet_id" {
  description = "The ID of the AKS subnet"
  value       = module.azurerm-aks.aks_subnet_id
}

# -----------------------------------------------------------------------------
# AKS Cluster Outputs
# -----------------------------------------------------------------------------

output "aks_cluster_id" {
  description = "The ID of the AKS cluster"
  value       = module.azurerm-aks.aks_cluster_id
}

output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.azurerm-aks.aks_cluster_name
}

output "aks_cluster_fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = module.azurerm-aks.aks_cluster_fqdn
}

output "aks_oidc_issuer_url" {
  description = "The OIDC issuer URL for workload identity"
  value       = module.azurerm-aks.aks_oidc_issuer_url
}

output "aks_node_resource_group" {
  description = "The auto-generated resource group for AKS nodes"
  value       = module.azurerm-aks.aks_node_resource_group
}

output "kube_config" {
  description = "Kubernetes config for connecting to the cluster"
  value       = module.azurerm-aks.kube_config
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Node Pool Outputs
# -----------------------------------------------------------------------------

output "node_pools" {
  description = "Map of additional node pool configurations"
  value       = module.azurerm-aks.node_pools
}

# -----------------------------------------------------------------------------
# Storage Account Outputs
# -----------------------------------------------------------------------------

output "storage_account_id" {
  description = "The ID of the storage account"
  value       = module.azurerm-aks.storage_account_id
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = module.azurerm-aks.storage_account_name
}

output "storage_account_primary_blob_endpoint" {
  description = "The primary blob endpoint of the storage account"
  value       = module.azurerm-aks.storage_account_primary_blob_endpoint
}

# -----------------------------------------------------------------------------
# Key Vault Outputs
# -----------------------------------------------------------------------------

output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = module.azurerm-aks.key_vault_id
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = module.azurerm-aks.key_vault_name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = module.azurerm-aks.key_vault_uri
}

# -----------------------------------------------------------------------------
# Workload Identity Outputs
# -----------------------------------------------------------------------------

output "workload_identities" {
  description = "Map of workload identity details"
  value       = module.azurerm-aks.workload_identities
}

output "workload_identity_federated_credentials" {
  description = "Map of federated credential details for Kubernetes service accounts"
  value       = module.azurerm-aks.workload_identity_federated_credentials
}

# -----------------------------------------------------------------------------
# Identity Outputs
# -----------------------------------------------------------------------------

output "aks_control_plane_identity_client_id" {
  description = "The Client ID of the AKS control plane managed identity"
  value       = module.azurerm-aks.aks_control_plane_identity_client_id
}

output "key_vault_secrets_provider_identity_client_id" {
  description = "The Client ID of the Key Vault Secrets Provider identity"
  value       = module.azurerm-aks.key_vault_secrets_provider_identity_client_id
}

# -----------------------------------------------------------------------------
# Cert-Manager Outputs
# -----------------------------------------------------------------------------

output "cert_manager_namespace" {
  description = "The namespace where cert-manager is installed"
  value       = var.enable_cert_manager ? module.cert_manager[0].namespace : null
}

output "cert_manager_issuers" {
  description = "Available ClusterIssuers for certificate generation"
  value = var.enable_cert_manager ? {
    self_signed         = module.cert_manager[0].self_signed_issuer_name
    letsencrypt_staging = module.cert_manager[0].letsencrypt_staging_issuer_name
    letsencrypt_prod    = module.cert_manager[0].letsencrypt_prod_issuer_name
  } : null
}
