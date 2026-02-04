# -----------------------------------------------------------------------------
# General Variables
# -----------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# AKS Cluster Variables
# -----------------------------------------------------------------------------

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "sku_tier" {
  description = "SKU tier for the AKS cluster (Free or Standard)"
  type        = string
  default     = "Free"
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Network Variables
# -----------------------------------------------------------------------------

variable "vnet_name" {
  description = "Name of the virtual network. If empty, will be auto-generated."
  type        = string
  default     = ""
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "aks_subnet_name" {
  description = "Name of the AKS subnet"
  type        = string
  default     = "aks-subnet"
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for the AKS subnet"
  type        = string
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
}

variable "dns_service_ip" {
  description = "IP address for Kubernetes DNS service"
  type        = string
}

# -----------------------------------------------------------------------------
# Node Pool Variables
# -----------------------------------------------------------------------------

variable "system_node_pool" {
  description = "Configuration for the system node pool"
  type = object({
    name                = optional(string, "system")
    vm_size             = optional(string, "Standard_D2s_v5")
    node_count          = optional(number, 2)
    min_count           = optional(number, 2)
    max_count           = optional(number, 5)
    os_disk_size_gb     = optional(number, 50)
    os_disk_type        = optional(string, "Managed")
    enable_auto_scaling = optional(bool, true)
    zones               = optional(list(string), ["1", "2", "3"])
  })
  default = {}
}

variable "node_pools" {
  description = "Map of additional node pools"
  type = map(object({
    vm_size                      = string
    node_count                   = optional(number, 1)
    min_count                    = optional(number, 1)
    max_count                    = optional(number, 10)
    os_disk_size_gb              = optional(number, 100)
    os_disk_type                 = optional(string, "Managed")
    enable_auto_scaling          = optional(bool, true)
    mode                         = optional(string, "User")
    zones                        = optional(list(string), ["1", "2", "3"])
    max_pods                     = optional(number, 30)
    node_labels                  = optional(map(string), {})
    node_taints                  = optional(list(string), [])
    priority                     = optional(string, "Regular")
    eviction_policy              = optional(string, null)
    spot_max_price               = optional(number, null)
    enable_host_encryption       = optional(bool, false)
    enable_node_public_ip        = optional(bool, false)
    ultra_ssd_enabled            = optional(bool, false)
    os_type                      = optional(string, "Linux")
    orchestrator_version         = optional(string, null)
    proximity_placement_group_id = optional(string, null)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Storage Account Variables
# -----------------------------------------------------------------------------

variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
}

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "storage_containers" {
  description = "List of storage containers"
  type = list(object({
    name        = string
    access_type = optional(string, "private")
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Key Vault Variables
# -----------------------------------------------------------------------------

variable "key_vault_name" {
  description = "Name of the Key Vault"
  type        = string
}

variable "key_vault_sku" {
  description = "SKU for the Key Vault"
  type        = string
  default     = "standard"
}

variable "key_vault_soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted Key Vault items"
  type        = number
  default     = 7
}

variable "key_vault_purge_protection_enabled" {
  description = "Enable purge protection for the Key Vault"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Workload Identity Variables
# -----------------------------------------------------------------------------

variable "workload_identities" {
  description = "Map of workload identities"
  type = map(object({
    namespace       = string
    service_account = string
    description     = optional(string, "")
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# RBAC Variables
# -----------------------------------------------------------------------------

variable "admin_group_object_ids" {
  description = "List of Azure AD group object IDs for cluster admin access"
  type        = list(string)
  default     = []
}

variable "azure_rbac_enabled" {
  description = "Enable Azure RBAC for Kubernetes authorization"
  type        = bool
  default     = true
}
