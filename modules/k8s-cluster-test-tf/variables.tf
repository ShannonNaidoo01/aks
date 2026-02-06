# -----------------------------------------------------------------------------
# Cluster Test Variables
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (dev, stg, prd)"
  type        = string
}

variable "hostname" {
  description = "Hostname for the ingress (e.g., test.dev.example.com)"
  type        = string
  default     = ""
}

variable "cluster_issuer" {
  description = "Cert-manager cluster issuer to use for TLS"
  type        = string
  default     = "letsencrypt-prod"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
