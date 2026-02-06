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
  default     = "1.32"
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
    vm_size             = string
    node_count          = optional(number, 2)
    min_count           = optional(number, 1)
    max_count           = optional(number, 10)
    os_disk_size_gb     = optional(number, 100)
    os_disk_type        = optional(string, "Managed")
    enable_auto_scaling = optional(bool, true)
    mode                = optional(string, "User")
    zones               = optional(list(string), ["1", "2", "3"])
    max_pods            = optional(number, 30)
    node_labels         = optional(map(string), {})
    node_taints         = optional(list(string), [])
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Storage Account Variables
# -----------------------------------------------------------------------------

variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique)"
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
  default = [{ name = "data" }]
}

# -----------------------------------------------------------------------------
# Key Vault Variables
# -----------------------------------------------------------------------------

variable "key_vault_name" {
  description = "Name of the Key Vault"
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
  description = "Map of workload identities to create"
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
# Ingress Controller Variables
# -----------------------------------------------------------------------------

variable "enable_ingress_nginx" {
  description = "Enable NGINX Ingress Controller deployment"
  type        = bool
  default     = true
}

variable "ingress_nginx_namespace" {
  description = "Kubernetes namespace for the ingress controller"
  type        = string
  default     = "ingress-nginx"
}

variable "ingress_nginx_chart_version" {
  description = "NGINX Ingress Controller Helm chart version"
  type        = string
  default     = "4.9.1"
}

variable "ingress_nginx_replica_count" {
  description = "Number of ingress controller replicas"
  type        = number
  default     = 2
}

variable "ingress_nginx_internal_lb" {
  description = "Use internal (private) load balancer instead of public"
  type        = bool
  default     = false
}

variable "ingress_nginx_default_ssl_secret" {
  description = "Name of the TLS secret to use as the default SSL certificate"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Cert-Manager Variables
# -----------------------------------------------------------------------------

variable "enable_cert_manager" {
  description = "Enable cert-manager deployment"
  type        = bool
  default     = true
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt registration"
  type        = string
  default     = ""
}

variable "ingress_class" {
  description = "Ingress class name for HTTP01 challenge solver"
  type        = string
  default     = "nginx"
}

variable "cert_manager_self_signed_issuer" {
  description = "Create a self-signed ClusterIssuer"
  type        = bool
  default     = true
}

variable "cert_manager_letsencrypt_issuers" {
  description = "Create Let's Encrypt ClusterIssuers"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Cluster Test Variables
# -----------------------------------------------------------------------------

variable "enable_cluster_test" {
  description = "Enable the cluster test static web app"
  type        = bool
  default     = false
}

variable "cluster_test_hostname" {
  description = "Hostname for the cluster test app"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# DNS Zone Variables
# -----------------------------------------------------------------------------

variable "dns_zones" {
  description = "Map of DNS zones to create"
  type = map(object({
    name = string
  }))
  default = {}
}

variable "existing_dns_zones" {
  description = "Map of existing DNS zones to use"
  type = map(object({
    name                = string
    resource_group_name = string
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Wildcard Certificate Variables
# -----------------------------------------------------------------------------

variable "wildcard_certificates" {
  description = "Map of wildcard certificates to create"
  type = map(object({
    dns_name         = string
    issuer_name      = string
    secret_name      = string
    target_namespace = optional(string, "default")
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Azure Entra Groups Variables
# -----------------------------------------------------------------------------

variable "enable_entra_groups" {
  description = "Enable Azure Entra group management"
  type        = bool
  default     = false
}

variable "entra_groups" {
  description = "Map of Azure Entra groups to create"
  type = map(object({
    display_name            = string
    description             = optional(string, "")
    security_enabled        = optional(bool, true)
    mail_enabled            = optional(bool, false)
    mail_nickname           = optional(string, null)
    prevent_duplicate_names = optional(bool, true)
    owners                  = optional(list(string), [])
    members = optional(object({
      users              = optional(list(string), [])
      service_principals = optional(list(string), [])
      groups             = optional(list(string), [])
    }), {})
  }))
  default = {}
}

variable "entra_existing_groups" {
  description = "Map of existing Azure Entra groups to manage"
  type = map(object({
    display_name = string
    members = optional(object({
      users              = optional(list(string), [])
      service_principals = optional(list(string), [])
      groups             = optional(list(string), [])
    }), {})
  }))
  default = {}
}

variable "entra_include_current_user_as_owner" {
  description = "Include the current user/SP as owner of created groups"
  type        = bool
  default     = true
}
