# -----------------------------------------------------------------------------
# General Variables
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (dev, stg, prd)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "uksouth"
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
  default     = ""
}

variable "kubernetes_version" {
  description = "Kubernetes version for the AKS cluster"
  type        = string
  default     = "1.29"
}

variable "aks_sku_tier" {
  description = "SKU tier for the AKS cluster (Free or Standard)"
  type        = string
  default     = "Standard"
}

variable "private_cluster_enabled" {
  description = "Enable private cluster (API server only accessible from VNet)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Network Variables
# -----------------------------------------------------------------------------

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_address_prefix" {
  description = "Address prefix for the AKS subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "10.1.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address for Kubernetes DNS service"
  type        = string
  default     = "10.1.0.10"
}

# -----------------------------------------------------------------------------
# Node Pool Variables
# -----------------------------------------------------------------------------

variable "system_node_pool" {
  description = "Configuration for the default system node pool"
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
  description = "Map of additional node pools to create"
  type = map(object({
    vm_size                      = string
    node_count                   = optional(number, 2)
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
  description = "Name of the storage account (must be globally unique). If empty, will be auto-generated."
  type        = string
  default     = ""
}

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "ZRS"
}

variable "storage_containers" {
  description = "List of storage containers to create"
  type = list(object({
    name        = string
    access_type = optional(string, "private")
  }))
  default = [
    { name = "data" }
  ]
}

# -----------------------------------------------------------------------------
# Key Vault Variables
# -----------------------------------------------------------------------------

variable "key_vault_name" {
  description = "Name of the Key Vault. If empty, will be auto-generated."
  type        = string
  default     = ""
}

variable "key_vault_sku" {
  description = "SKU for the Key Vault"
  type        = string
  default     = "standard"
}

# -----------------------------------------------------------------------------
# Workload Identity Variables
# -----------------------------------------------------------------------------

variable "workload_identities" {
  description = "Map of workload identities to create for applications"
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

# -----------------------------------------------------------------------------
# Cert-Manager Variables
# -----------------------------------------------------------------------------

variable "enable_cert_manager" {
  description = "Enable cert-manager deployment"
  type        = bool
  default     = true
}

variable "cert_manager_version" {
  description = "Cert-manager Helm chart version"
  type        = string
  default     = "v1.14.3"
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt certificate notifications"
  type        = string
  default     = ""
}
