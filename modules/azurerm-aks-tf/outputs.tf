# -----------------------------------------------------------------------------
# Resource Group Outputs
# -----------------------------------------------------------------------------

output "resource_group_id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.aks.id
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.aks.name
}

output "resource_group_location" {
  description = "The location of the resource group"
  value       = azurerm_resource_group.aks.location
}

# -----------------------------------------------------------------------------
# Network Outputs
# -----------------------------------------------------------------------------

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.aks.id
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.aks.name
}

output "aks_subnet_id" {
  description = "The ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

# -----------------------------------------------------------------------------
# AKS Identity Outputs
# -----------------------------------------------------------------------------

output "aks_control_plane_identity_id" {
  description = "The ID of the AKS control plane managed identity"
  value       = azurerm_user_assigned_identity.aks_control_plane.id
}

output "aks_control_plane_identity_client_id" {
  description = "The Client ID of the AKS control plane managed identity"
  value       = azurerm_user_assigned_identity.aks_control_plane.client_id
}

output "aks_control_plane_identity_principal_id" {
  description = "The Principal ID of the AKS control plane managed identity"
  value       = azurerm_user_assigned_identity.aks_control_plane.principal_id
}

# -----------------------------------------------------------------------------
# AKS Cluster Outputs
# -----------------------------------------------------------------------------

output "aks_cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "aks_oidc_issuer_url" {
  description = "The OIDC issuer URL"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "aks_node_resource_group" {
  description = "The auto-generated resource group for AKS nodes"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "kube_config" {
  description = "Kubernetes config"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "kube_config_host" {
  description = "Kubernetes API server host"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].host
  sensitive   = true
}

output "kube_config_client_certificate" {
  description = "Kubernetes client certificate (base64 encoded)"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate
  sensitive   = true
}

output "kube_config_client_key" {
  description = "Kubernetes client key (base64 encoded)"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].client_key
  sensitive   = true
}

output "kube_config_cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate (base64 encoded)"
  value       = azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Admin Kubeconfig Outputs (for Azure RBAC clusters - bypasses AAD auth)
# -----------------------------------------------------------------------------

output "kube_admin_config_host" {
  description = "Kubernetes API server host (admin)"
  value       = azurerm_kubernetes_cluster.aks.kube_admin_config[0].host
  sensitive   = true
}

output "kube_admin_config_client_certificate" {
  description = "Kubernetes admin client certificate (base64 encoded)"
  value       = azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_certificate
  sensitive   = true
}

output "kube_admin_config_client_key" {
  description = "Kubernetes admin client key (base64 encoded)"
  value       = azurerm_kubernetes_cluster.aks.kube_admin_config[0].client_key
  sensitive   = true
}

output "kube_admin_config_cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate (base64 encoded, admin)"
  value       = azurerm_kubernetes_cluster.aks.kube_admin_config[0].cluster_ca_certificate
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Key Vault Secrets Provider Outputs
# -----------------------------------------------------------------------------

output "key_vault_secrets_provider_identity_client_id" {
  description = "The Client ID of the Key Vault Secrets Provider identity"
  value       = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].client_id
}

output "key_vault_secrets_provider_identity_object_id" {
  description = "The Object ID of the Key Vault Secrets Provider identity"
  value       = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id
}

# -----------------------------------------------------------------------------
# Node Pool Outputs
# -----------------------------------------------------------------------------

output "node_pools" {
  description = "Map of node pool configurations"
  value = {
    for k, v in azurerm_kubernetes_cluster_node_pool.additional : k => {
      id      = v.id
      name    = v.name
      vm_size = v.vm_size
    }
  }
}

# -----------------------------------------------------------------------------
# Storage Account Outputs
# -----------------------------------------------------------------------------

output "storage_account_id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.aks.id
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.aks.name
}

output "storage_account_primary_blob_endpoint" {
  description = "The primary blob endpoint"
  value       = azurerm_storage_account.aks.primary_blob_endpoint
}

# -----------------------------------------------------------------------------
# Key Vault Outputs
# -----------------------------------------------------------------------------

output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.aks.id
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.aks.name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.aks.vault_uri
}

# -----------------------------------------------------------------------------
# Workload Identity Outputs
# -----------------------------------------------------------------------------

output "workload_identities" {
  description = "Map of workload identity details"
  value = {
    for k, v in azurerm_user_assigned_identity.workload : k => {
      id           = v.id
      client_id    = v.client_id
      principal_id = v.principal_id
    }
  }
}

output "workload_identity_federated_credentials" {
  description = "Map of federated credential details"
  value = {
    for k, v in azurerm_federated_identity_credential.workload : k => {
      id      = v.id
      name    = v.name
      subject = v.subject
    }
  }
}

# -----------------------------------------------------------------------------
# DNS Zone Outputs
# -----------------------------------------------------------------------------

output "dns_zones" {
  description = "Map of created DNS zone details"
  value = {
    for k, v in azurerm_dns_zone.zones : k => {
      id                  = v.id
      name                = v.name
      name_servers        = v.name_servers
      resource_group_name = v.resource_group_name
    }
  }
}

output "existing_dns_zones" {
  description = "Map of existing DNS zone details"
  value = {
    for k, v in data.azurerm_dns_zone.existing : k => {
      id                  = v.id
      name                = v.name
      name_servers        = v.name_servers
      resource_group_name = v.resource_group_name
    }
  }
}

# Combined output for all DNS zones (both created and existing)
output "all_dns_zones" {
  description = "Map of all DNS zone details (created and existing)"
  value = merge(
    {
      for k, v in azurerm_dns_zone.zones : k => {
        id                  = v.id
        name                = v.name
        name_servers        = v.name_servers
        resource_group_name = v.resource_group_name
      }
    },
    {
      for k, v in data.azurerm_dns_zone.existing : k => {
        id                  = v.id
        name                = v.name
        name_servers        = v.name_servers
        resource_group_name = v.resource_group_name
      }
    }
  )
}

output "subscription_id" {
  description = "The Azure subscription ID (needed for cert-manager DNS01 solver)"
  value       = data.azurerm_client_config.current.subscription_id
}
