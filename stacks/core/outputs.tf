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

output "kube_admin_config_host" {
  description = "Kubernetes API server host (admin credentials)"
  value       = module.azurerm-aks.kube_admin_config_host
  sensitive   = true
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

# -----------------------------------------------------------------------------
# Ingress Controller Outputs
# -----------------------------------------------------------------------------

output "ingress_nginx_load_balancer_ip" {
  description = "The external IP address of the NGINX ingress controller"
  value       = var.enable_ingress_nginx ? module.ingress_nginx[0].load_balancer_ip : null
}

output "ingress_nginx_class_name" {
  description = "The IngressClass name to use in Ingress resources"
  value       = var.enable_ingress_nginx ? module.ingress_nginx[0].ingress_class_name : null
}

# -----------------------------------------------------------------------------
# DNS Zone Outputs
# -----------------------------------------------------------------------------

output "dns_zones" {
  description = "Map of created DNS zone details"
  value       = module.azurerm-aks.dns_zones
}

output "all_dns_zones" {
  description = "Map of all DNS zone details (created and existing)"
  value       = module.azurerm-aks.all_dns_zones
}

# -----------------------------------------------------------------------------
# Cluster Test Outputs
# -----------------------------------------------------------------------------

output "cluster_test_url" {
  description = "The URL to access the cluster test app"
  value       = var.enable_cluster_test ? module.cluster_test[0].url : null
}

# -----------------------------------------------------------------------------
# Azure Entra Groups Outputs
# -----------------------------------------------------------------------------

output "entra_groups" {
  description = "Map of created Azure Entra group details"
  value       = var.enable_entra_groups ? module.entra_groups[0].groups : {}
}
