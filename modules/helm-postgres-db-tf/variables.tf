# -----------------------------------------------------------------------------
# PostgreSQL Server Reference
# -----------------------------------------------------------------------------

variable "postgres_namespace" {
  description = "Namespace where PostgreSQL server is deployed"
  type        = string
  default     = "postgres"
}

variable "postgres_host" {
  description = "Direct PostgreSQL host (for admin/DDL operations)"
  type        = string
}

variable "pgbouncer_host" {
  description = "PgBouncer host for read-write connections"
  type        = string
}

variable "pgbouncer_host_ro" {
  description = "PgBouncer host for read-only connections (replicas)"
  type        = string
  default     = "" # If empty, uses pgbouncer_host
}

variable "postgres_superuser_secret" {
  description = "Name of the secret containing superuser credentials"
  type        = string
}

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------

variable "database_name" {
  description = "Name of the database to create"
  type        = string
}

variable "database_user" {
  description = "Username for the database (defaults to database_name)"
  type        = string
  default     = ""
}

variable "extensions" {
  description = "List of PostgreSQL extensions to install"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Key Vault Integration (Optional)
# -----------------------------------------------------------------------------

variable "key_vault_id" {
  description = "Azure Key Vault ID to store connection string (optional)"
  type        = string
  default     = ""
}
