# -----------------------------------------------------------------------------
# General Configuration
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (dev, stg, prd)"
  type        = string
}

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

# -----------------------------------------------------------------------------
# Operator Configuration
# -----------------------------------------------------------------------------

variable "operator_version" {
  description = "CloudNativePG operator Helm chart version"
  type        = string
  default     = "0.20.0"
}

variable "postgres_version" {
  description = "PostgreSQL version (image tag)"
  type        = string
  default     = "16.2"
}

# -----------------------------------------------------------------------------
# Cluster Configuration
# -----------------------------------------------------------------------------

variable "instances" {
  description = "Number of PostgreSQL instances (replicas)"
  type        = number
  default     = 1
}

variable "default_database" {
  description = "Default database to create"
  type        = string
  default     = "app"
}

variable "default_user" {
  description = "Default database user/owner"
  type        = string
  default     = "app"
}

# -----------------------------------------------------------------------------
# PostgreSQL Parameters
# -----------------------------------------------------------------------------

variable "max_connections" {
  description = "Maximum number of connections (direct to PostgreSQL)"
  type        = number
  default     = 100
}

variable "shared_buffers" {
  description = "Shared buffers size"
  type        = string
  default     = "256MB"
}

variable "effective_cache_size" {
  description = "Effective cache size"
  type        = string
  default     = "768MB"
}

variable "maintenance_work_mem" {
  description = "Maintenance work memory"
  type        = string
  default     = "64MB"
}

# -----------------------------------------------------------------------------
# Resource Configuration (PostgreSQL)
# -----------------------------------------------------------------------------

variable "storage_size" {
  description = "Storage size for each PostgreSQL instance"
  type        = string
  default     = "10Gi"
}

variable "storage_class" {
  description = "Kubernetes storage class"
  type        = string
  default     = "managed-csi"
}

variable "cpu_request" {
  description = "CPU request for each PostgreSQL instance"
  type        = string
  default     = "250m"
}

variable "cpu_limit" {
  description = "CPU limit for each PostgreSQL instance"
  type        = string
  default     = "1000m"
}

variable "memory_request" {
  description = "Memory request for each PostgreSQL instance"
  type        = string
  default     = "512Mi"
}

variable "memory_limit" {
  description = "Memory limit for each PostgreSQL instance"
  type        = string
  default     = "1Gi"
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
  description = "PgBouncer pool mode: session, transaction, or statement"
  type        = string
  default     = "transaction"
}

variable "pgbouncer_max_client_conn" {
  description = "Maximum number of client connections to PgBouncer"
  type        = number
  default     = 1000
}

variable "pgbouncer_default_pool_size" {
  description = "Default number of server connections per user/database pair"
  type        = number
  default     = 25
}

variable "pgbouncer_min_pool_size" {
  description = "Minimum number of server connections to keep in pool"
  type        = number
  default     = 5
}

variable "pgbouncer_reserve_pool_size" {
  description = "Additional connections for burst traffic"
  type        = number
  default     = 5
}

variable "pgbouncer_reserve_pool_timeout" {
  description = "Seconds to wait before using reserve pool"
  type        = number
  default     = 3
}

variable "pgbouncer_enable_ro_pooler" {
  description = "Enable read-only pooler for read replicas"
  type        = bool
  default     = true
}

# PgBouncer Resources
variable "pgbouncer_cpu_request" {
  description = "CPU request for PgBouncer pods"
  type        = string
  default     = "100m"
}

variable "pgbouncer_cpu_limit" {
  description = "CPU limit for PgBouncer pods"
  type        = string
  default     = "500m"
}

variable "pgbouncer_memory_request" {
  description = "Memory request for PgBouncer pods"
  type        = string
  default     = "128Mi"
}

variable "pgbouncer_memory_limit" {
  description = "Memory limit for PgBouncer pods"
  type        = string
  default     = "256Mi"
}

# -----------------------------------------------------------------------------
# Backup Configuration
# -----------------------------------------------------------------------------

variable "enable_backups" {
  description = "Enable backups to object storage"
  type        = bool
  default     = false
}

variable "backup_bucket" {
  description = "S3/Azure Blob bucket for backups"
  type        = string
  default     = ""
}

variable "backup_endpoint" {
  description = "S3-compatible endpoint URL"
  type        = string
  default     = ""
}

variable "backup_retention" {
  description = "Backup retention policy"
  type        = string
  default     = "30d"
}

# -----------------------------------------------------------------------------
# Monitoring Configuration
# -----------------------------------------------------------------------------

variable "enable_monitoring" {
  description = "Enable Prometheus monitoring"
  type        = bool
  default     = false
}
