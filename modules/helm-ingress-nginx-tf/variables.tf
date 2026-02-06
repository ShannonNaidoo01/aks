# -----------------------------------------------------------------------------
# General Configuration
# -----------------------------------------------------------------------------

variable "namespace" {
  description = "Kubernetes namespace for the ingress controller"
  type        = string
  default     = "ingress-nginx"
}

variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "ingress-nginx"
}

variable "chart_version" {
  description = "NGINX Ingress Controller Helm chart version"
  type        = string
  default     = "4.9.1"
}

variable "helm_timeout" {
  description = "Timeout for Helm operations in seconds"
  type        = number
  default     = 600
}

# -----------------------------------------------------------------------------
# Controller Configuration
# -----------------------------------------------------------------------------

variable "replica_count" {
  description = "Number of ingress controller replicas"
  type        = number
  default     = 2
}

variable "ingress_class_name" {
  description = "Name of the IngressClass resource"
  type        = string
  default     = "nginx"
}

variable "default_ingress_class" {
  description = "Set as the default ingress class"
  type        = bool
  default     = true
}

variable "min_available" {
  description = "Minimum available pods for PodDisruptionBudget"
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# Load Balancer Configuration
# -----------------------------------------------------------------------------

variable "external_traffic_policy" {
  description = "External traffic policy for the LoadBalancer service (Local or Cluster)"
  type        = string
  default     = "Local"

  validation {
    condition     = contains(["Local", "Cluster"], var.external_traffic_policy)
    error_message = "external_traffic_policy must be 'Local' or 'Cluster'."
  }
}

variable "internal_load_balancer" {
  description = "Create an internal (private) load balancer instead of public"
  type        = bool
  default     = false
}

variable "load_balancer_ip" {
  description = "Static IP address for the LoadBalancer (leave empty for dynamic assignment)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Resource Configuration
# -----------------------------------------------------------------------------

variable "resources" {
  description = "Resource requests and limits for the ingress controller"
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
      cpu    = "100m"
      memory = "90Mi"
    }
    limits = {
      cpu    = "500m"
      memory = "256Mi"
    }
  }
}

# -----------------------------------------------------------------------------
# Monitoring Configuration
# -----------------------------------------------------------------------------

variable "metrics_enabled" {
  description = "Enable Prometheus metrics"
  type        = bool
  default     = true
}

variable "service_monitor_enabled" {
  description = "Enable ServiceMonitor for Prometheus Operator"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Security Configuration
# -----------------------------------------------------------------------------

variable "admission_webhooks_enabled" {
  description = "Enable admission webhooks for ingress validation"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Customization
# -----------------------------------------------------------------------------

variable "additional_set_values" {
  description = "Additional Helm set values"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "values_file" {
  description = "Path to a custom values.yaml file"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Default SSL Certificate
# -----------------------------------------------------------------------------

variable "default_ssl_certificate_secret" {
  description = "Name of the TLS secret to use as the default SSL certificate (e.g., 'wildcard-tls'). Must exist in the ingress-nginx namespace."
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Tags (for documentation/reference)
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags for documentation purposes"
  type        = map(string)
  default     = {}
}
