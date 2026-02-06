# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# -----------------------------------------------------------------------------
# Virtual Network and Subnet for Azure CNI
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "aks" {
  name                = var.vnet_name != "" ? var.vnet_name : "${var.aks_cluster_name}-vnet"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  name                 = var.aks_subnet_name
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = [var.aks_subnet_address_prefix]
}

# -----------------------------------------------------------------------------
# User Assigned Managed Identity for AKS Control Plane
# -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "aks_control_plane" {
  name                = "${var.aks_cluster_name}-identity"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  tags                = var.tags
}

# Grant the AKS identity Network Contributor on the subnet
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_subnet.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_control_plane.principal_id
}

# -----------------------------------------------------------------------------
# AKS Cluster with Azure CNI
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = var.aks_cluster_name
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  private_cluster_enabled = var.private_cluster_enabled

  # Use User Assigned Managed Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_control_plane.id]
  }

  # Default system node pool
  default_node_pool {
    name                 = var.system_node_pool.name
    vm_size              = var.system_node_pool.vm_size
    node_count           = var.system_node_pool.enable_auto_scaling ? null : var.system_node_pool.node_count
    min_count            = var.system_node_pool.enable_auto_scaling ? var.system_node_pool.min_count : null
    max_count            = var.system_node_pool.enable_auto_scaling ? var.system_node_pool.max_count : null
    os_disk_size_gb      = var.system_node_pool.os_disk_size_gb
    os_disk_type         = var.system_node_pool.os_disk_type
    vnet_subnet_id       = azurerm_subnet.aks.id
    zones                = var.system_node_pool.zones
    auto_scaling_enabled = var.system_node_pool.enable_auto_scaling

    upgrade_settings {
      max_surge = "10%"
    }
  }

  # Azure CNI Network Configuration
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    load_balancer_sku = "standard"
  }

  # Enable workload identity and OIDC issuer
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Azure AD RBAC integration
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = var.azure_rbac_enabled
    admin_group_object_ids = var.admin_group_object_ids
  }

  # Key management
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  tags = var.tags

  depends_on = [
    azurerm_role_assignment.aks_network_contributor
  ]
}

# -----------------------------------------------------------------------------
# Additional Node Pools
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = each.value.vm_size
  node_count            = each.value.enable_auto_scaling ? null : each.value.node_count
  min_count             = each.value.enable_auto_scaling ? each.value.min_count : null
  max_count             = each.value.enable_auto_scaling ? each.value.max_count : null
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = each.value.os_disk_type
  auto_scaling_enabled  = each.value.enable_auto_scaling
  mode                  = each.value.mode
  zones                 = each.value.zones
  max_pods              = each.value.max_pods
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints
  priority              = each.value.priority
  eviction_policy       = each.value.eviction_policy
  spot_max_price        = each.value.spot_max_price
  os_type               = each.value.os_type
  orchestrator_version  = each.value.orchestrator_version
  ultra_ssd_enabled     = each.value.ultra_ssd_enabled
  vnet_subnet_id        = azurerm_subnet.aks.id

  host_encryption_enabled = each.value.enable_host_encryption
  node_public_ip_enabled  = each.value.enable_node_public_ip

  upgrade_settings {
    max_surge = "10%"
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Storage Account
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "aks" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.aks.name
  location                 = azurerm_resource_group.aks.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type

  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

resource "azurerm_storage_container" "containers" {
  for_each = { for c in var.storage_containers : c.name => c }

  name                  = each.value.name
  storage_account_id    = azurerm_storage_account.aks.id
  container_access_type = each.value.access_type
}

# -----------------------------------------------------------------------------
# Key Vault
# -----------------------------------------------------------------------------

resource "azurerm_key_vault" "aks" {
  name                       = var.key_vault_name
  location                   = azurerm_resource_group.aks.location
  resource_group_name        = azurerm_resource_group.aks.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.key_vault_sku
  soft_delete_retention_days = var.key_vault_soft_delete_retention_days
  purge_protection_enabled   = var.key_vault_purge_protection_enabled

  rbac_authorization_enabled = true

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = var.tags
}

# Grant current deployment identity Key Vault Administrator
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.aks.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Grant AKS cluster Key Vault Secrets User
resource "azurerm_role_assignment" "aks_kv_secrets_user" {
  scope                = azurerm_key_vault.aks.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id
}

# -----------------------------------------------------------------------------
# Workload Identities for Applications
# -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "workload" {
  for_each = var.workload_identities

  name                = "${var.aks_cluster_name}-${each.key}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  tags                = var.tags
}

# Federated credentials for workload identity
resource "azurerm_federated_identity_credential" "workload" {
  for_each = var.workload_identities

  name                = each.key
  resource_group_name = azurerm_resource_group.aks.name
  parent_id           = azurerm_user_assigned_identity.workload[each.key].id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject             = "system:serviceaccount:${each.value.namespace}:${each.value.service_account}"
}

# -----------------------------------------------------------------------------
# Role Assignments for Workload Identities
# -----------------------------------------------------------------------------

# Storage access identity - Storage Blob Data Contributor
resource "azurerm_role_assignment" "storage_blob_contributor" {
  count = contains(keys(var.workload_identities), "storage-access") ? 1 : 0

  scope                = azurerm_storage_account.aks.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.workload["storage-access"].principal_id
}

# All workload identities get Key Vault Secrets User
resource "azurerm_role_assignment" "workload_kv_secrets_user" {
  for_each = var.workload_identities

  scope                = azurerm_key_vault.aks.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload[each.key].principal_id
}

# -----------------------------------------------------------------------------
# Store Workload Identity Details in Key Vault
# -----------------------------------------------------------------------------

resource "azurerm_key_vault_secret" "workload_identity_client_id" {
  for_each = var.workload_identities

  name         = "${each.key}-client-id"
  value        = azurerm_user_assigned_identity.workload[each.key].client_id
  key_vault_id = azurerm_key_vault.aks.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "workload_identity_tenant_id" {
  for_each = var.workload_identities

  name         = "${each.key}-tenant-id"
  value        = data.azurerm_client_config.current.tenant_id
  key_vault_id = azurerm_key_vault.aks.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

# -----------------------------------------------------------------------------
# Azure DNS Zones (for cert-manager DNS-01 challenges)
# -----------------------------------------------------------------------------

# Create new DNS zones (if specified)
resource "azurerm_dns_zone" "zones" {
  for_each = var.dns_zones

  name                = each.value.name
  resource_group_name = azurerm_resource_group.aks.name
  tags                = var.tags
}

# Reference existing DNS zones (if specified)
data "azurerm_dns_zone" "existing" {
  for_each = var.existing_dns_zones

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
}

# Grant DNS Zone Contributor to cert-manager workload identity (for created zones)
resource "azurerm_role_assignment" "dns_zone_contributor" {
  for_each = contains(keys(var.workload_identities), "cert-manager") ? var.dns_zones : {}

  scope                = azurerm_dns_zone.zones[each.key].id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.workload["cert-manager"].principal_id
}

# Grant DNS Zone Contributor to cert-manager workload identity (for existing zones)
resource "azurerm_role_assignment" "dns_zone_contributor_existing" {
  for_each = contains(keys(var.workload_identities), "cert-manager") ? var.existing_dns_zones : {}

  scope                = data.azurerm_dns_zone.existing[each.key].id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.workload["cert-manager"].principal_id
}
