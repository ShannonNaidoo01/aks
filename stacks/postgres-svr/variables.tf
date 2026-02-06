# -----------------------------------------------------------------------------
# Environment Configuration
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (dev, stg, prd)"
  type        = string
}

# -----------------------------------------------------------------------------
# AKS Cluster Reference
# -----------------------------------------------------------------------------

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "aks_resource_group" {
  description = "Resource group containing the AKS cluster"
  type        = string
}

# -----------------------------------------------------------------------------
# PostgreSQL Configuration
# -----------------------------------------------------------------------------

variable "namespace" {
  description = "Kubernetes namespace for PostgreSQL"
  type        = string
  default     = "postgres"
}

variable "cluster_name" {
  description = "Name of the PostgreSQL cluster"
  type        = string
  default     = "postgres-cluster"
}

variable "instances" {
  description = "Number of PostgreSQL instances"
  type        = number
  default     = 1
}

variable "storage_size" {
  description = "Storage size per instance"
  type        = string
  default     = "10Gi"
}

variable "storage_class" {
  description = "Kubernetes storage class"
  type        = string
  default     = "managed-csi"
}

# -----------------------------------------------------------------------------
# Resource Configuration (PostgreSQL)
# -----------------------------------------------------------------------------

variable "cpu_request" {
  description = "CPU request for PostgreSQL"
  type        = string
  default     = "250m"
}

variable "cpu_limit" {
  description = "CPU limit for PostgreSQL"
  type        = string
  default     = "1000m"
}

variable "memory_request" {
  description = "Memory request for PostgreSQL"
  type        = string
  default     = "512Mi"
}

variable "memory_limit" {
  description = "Memory limit for PostgreSQL"
  type        = string
  default     = "1Gi"
}

# -----------------------------------------------------------------------------
# PostgreSQL Parameters
# -----------------------------------------------------------------------------

variable "max_connections" {
  description = "Maximum connections (direct to PostgreSQL)"
  type        = number
  default     = 100
}

variable "shared_buffers" {
  description = "Shared buffers"
  type        = string
  default     = "256MB"
}

# -----------------------------------------------------------------------------
# PgBouncer Configuration
# -----------------------------------------------------------------------------

variable "pgbouncer_instances" {
  description = "Number of PgBouncer instances"
  type        = number
  default     = 2
}

variable "pgbouncer_pool_mode" {
  description = "Pool mode: session, transaction, or statement"
  type        = string
  default     = "transaction"
}

variable "pgbouncer_max_client_conn" {
  description = "Maximum client connections to PgBouncer"
  type        = number
  default     = 1000
}

variable "pgbouncer_default_pool_size" {
  description = "Default pool size per user/database"
  type        = number
  default     = 25
}

variable "pgbouncer_enable_ro_pooler" {
  description = "Enable read-only pooler (for read replicas)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Backup Configuration
# -----------------------------------------------------------------------------

variable "enable_backups" {
  description = "Enable backups"
  type        = bool
  default     = false
}

variable "backup_bucket" {
  description = "Backup bucket name"
  type        = string
  default     = ""
}

variable "backup_endpoint" {
  description = "Backup endpoint URL"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------

variable "enable_monitoring" {
  description = "Enable Prometheus monitoring"
  type        = bool
  default     = false
}
