# -----------------------------------------------------------------------------
# PostgreSQL Server Stack Outputs
# -----------------------------------------------------------------------------

output "namespace" {
  description = "Namespace where PostgreSQL is deployed"
  value       = module.postgres_server.namespace
}

output "cluster_name" {
  description = "PostgreSQL cluster name"
  value       = module.postgres_server.cluster_name
}

# -----------------------------------------------------------------------------
# PgBouncer Endpoints (RECOMMENDED - use these for applications)
# -----------------------------------------------------------------------------

output "host" {
  description = "PgBouncer host for read-write connections (use this for apps)"
  value       = module.postgres_server.host
}

output "host_ro" {
  description = "PgBouncer host for read-only connections"
  value       = module.postgres_server.host_ro
}

output "port" {
  description = "PgBouncer port"
  value       = module.postgres_server.port
}

output "pooler_service_rw" {
  description = "PgBouncer read-write service name"
  value       = module.postgres_server.pooler_service_rw
}

output "pooler_service_ro" {
  description = "PgBouncer read-only service name"
  value       = module.postgres_server.pooler_service_ro
}

# -----------------------------------------------------------------------------
# Direct PostgreSQL Endpoints (admin/migration tasks only)
# -----------------------------------------------------------------------------

output "postgres_host" {
  description = "Direct PostgreSQL host (admin only, bypasses PgBouncer)"
  value       = module.postgres_server.postgres_host
}

output "postgres_host_ro" {
  description = "Direct PostgreSQL read-only host (admin only)"
  value       = module.postgres_server.postgres_host_ro
}

# -----------------------------------------------------------------------------
# Credentials
# -----------------------------------------------------------------------------

output "superuser_secret_name" {
  description = "Kubernetes secret containing superuser credentials"
  value       = module.postgres_server.superuser_secret_name
}

# -----------------------------------------------------------------------------
# Connection Templates
# -----------------------------------------------------------------------------

output "connection_string_template" {
  description = "Connection string via PgBouncer (recommended)"
  value       = module.postgres_server.connection_string_template
}

output "connection_string_direct_template" {
  description = "Direct connection string (admin only)"
  value       = module.postgres_server.connection_string_direct_template
}

# -----------------------------------------------------------------------------
# PgBouncer Info
# -----------------------------------------------------------------------------

output "pgbouncer_pool_mode" {
  description = "PgBouncer pool mode (transaction, session, statement)"
  value       = module.postgres_server.pgbouncer_pool_mode
}

output "pgbouncer_max_connections" {
  description = "Maximum client connections to PgBouncer"
  value       = module.postgres_server.pgbouncer_max_connections
}
