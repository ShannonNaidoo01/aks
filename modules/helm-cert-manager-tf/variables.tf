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
# Extra Configuration
# -----------------------------------------------------------------------------

variable "extra_values" {
  description = "Extra Helm values to set"
  type        = map(string)
  default     = {}
}
