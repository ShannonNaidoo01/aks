# -----------------------------------------------------------------------------
# General Configuration
# -----------------------------------------------------------------------------

variable "namespace" {
  description = "Kubernetes namespace for cert-manager"
  type        = string
  default     = "cert-manager"
}

variable "chart_version" {
  description = "Cert-manager Helm chart version"
  type        = string
  default     = "v1.14.3"
}

variable "helm_timeout" {
  description = "Helm release timeout in seconds"
  type        = number
  default     = 600
}

# -----------------------------------------------------------------------------
# Resource Configuration
# -----------------------------------------------------------------------------

variable "resources" {
  description = "Resource requests and limits for cert-manager controller"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "10m"
      memory = "32Mi"
    }
    limits = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
}

# -----------------------------------------------------------------------------
# ClusterIssuer Configuration
# -----------------------------------------------------------------------------

variable "create_self_signed_issuer" {
  description = "Create a self-signed ClusterIssuer"
  type        = bool
  default     = true
}

variable "create_letsencrypt_issuers" {
  description = "Create Let's Encrypt staging and production ClusterIssuers"
  type        = bool
  default     = true
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt registration and notifications"
  type        = string
  default     = ""
}

variable "ingress_class" {
  description = "Ingress class name for HTTP01 challenge solver"
  type        = string
  default     = "nginx"
}

# -----------------------------------------------------------------------------
# Monitoring Configuration
# -----------------------------------------------------------------------------

variable "enable_prometheus_metrics" {
  description = "Enable Prometheus metrics endpoint"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# DNS-01 Challenge Configuration (for wildcard certificates)
# -----------------------------------------------------------------------------

variable "enable_dns01_solver" {
  description = "Enable DNS-01 challenge solver for wildcard certificates"
  type        = bool
  default     = false
}

variable "azure_dns_zone_name" {
  description = "Name of the Azure DNS Zone (e.g., dev.tune.exchange)"
  type        = string
  default     = ""
}

variable "azure_dns_zone_resource_group" {
  description = "Resource group containing the Azure DNS Zone"
  type        = string
  default     = ""
}

variable "azure_subscription_id" {
  description = "Azure subscription ID for DNS Zone access"
  type        = string
  default     = ""
}

variable "cert_manager_service_account" {
  description = "Service account name for cert-manager (for workload identity)"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_client_id" {
  description = "Client ID of the cert-manager workload identity"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Wildcard Certificate Configuration
# -----------------------------------------------------------------------------

variable "wildcard_certificates" {
  description = "Map of wildcard certificates to create"
  type = map(object({
    dns_name         = string                      # e.g., "*.dev.tune.exchange"
    issuer_name      = string                      # e.g., "letsencrypt-dns-prod"
    secret_name      = string                      # e.g., "wildcard-dev-tune-exchange-tls"
    target_namespace = optional(string, "default") # Namespace to create the secret in
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Extra Configuration
# -----------------------------------------------------------------------------

variable "extra_values" {
  description = "Extra Helm values to set"
  type        = map(string)
  default     = {}
}
