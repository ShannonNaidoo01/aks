# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------

output "database_name" {
  description = "The name of the database"
  value       = var.database_name
}

output "database_user" {
  description = "The database user"
  value       = var.database_user != "" ? var.database_user : var.database_name
}

output "credentials_secret_name" {
  description = "Name of the Kubernetes secret containing credentials"
  value       = kubernetes_secret_v1.db_credentials.metadata[0].name
}

output "credentials_secret_namespace" {
  description = "Namespace of the credentials secret"
  value       = kubernetes_secret_v1.db_credentials.metadata[0].namespace
}

# -----------------------------------------------------------------------------
# PgBouncer Connection (RECOMMENDED for applications)
# -----------------------------------------------------------------------------

output "host" {
  description = "PgBouncer host for read-write (primary)"
  value       = var.pgbouncer_host
}

output "host_ro" {
  description = "PgBouncer host for read-only (replicas)"
  value       = var.pgbouncer_host_ro != "" ? var.pgbouncer_host_ro : var.pgbouncer_host
}

output "connection_string" {
  description = "Connection string via PgBouncer - read/write"
  value       = "postgresql://${var.database_user != "" ? var.database_user : var.database_name}:PASSWORD@${var.pgbouncer_host}:5432/${var.database_name}"
  sensitive   = true
}

output "connection_string_ro" {
  description = "Connection string via PgBouncer - read-only (replicas)"
  value       = "postgresql://${var.database_user != "" ? var.database_user : var.database_name}:PASSWORD@${var.pgbouncer_host_ro != "" ? var.pgbouncer_host_ro : var.pgbouncer_host}:5432/${var.database_name}"
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Direct PostgreSQL Connection (admin/migration only)
# -----------------------------------------------------------------------------

output "host_direct" {
  description = "Direct PostgreSQL host (admin only)"
  value       = var.postgres_host
}

output "connection_string_direct" {
  description = "Direct connection string (admin only)"
  value       = "postgresql://${var.database_user != "" ? var.database_user : var.database_name}:PASSWORD@${var.postgres_host}:5432/${var.database_name}"
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Common
# -----------------------------------------------------------------------------

output "port" {
  description = "Database port"
  value       = 5432
}
