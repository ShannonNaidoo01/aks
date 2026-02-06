# -----------------------------------------------------------------------------
# PostgreSQL Server Outputs
# -----------------------------------------------------------------------------

output "namespace" {
  description = "The namespace where PostgreSQL is deployed"
  value       = kubernetes_namespace_v1.postgres.metadata[0].name
}

output "cluster_name" {
  description = "The name of the PostgreSQL cluster"
  value       = var.cluster_name
}

# -----------------------------------------------------------------------------
# Direct PostgreSQL Endpoints (for admin tasks only)
# -----------------------------------------------------------------------------

output "postgres_service_rw" {
  description = "Direct PostgreSQL read-write service (admin only)"
  value       = "${var.cluster_name}-rw"
}

output "postgres_service_ro" {
  description = "Direct PostgreSQL read-only service (admin only)"
  value       = "${var.cluster_name}-ro"
}

output "postgres_host" {
  description = "Direct PostgreSQL host (admin only)"
  value       = "${var.cluster_name}-rw.${kubernetes_namespace_v1.postgres.metadata[0].name}.svc.cluster.local"
}

output "postgres_host_ro" {
  description = "Direct PostgreSQL read-only host (admin only)"
  value       = "${var.cluster_name}-ro.${kubernetes_namespace_v1.postgres.metadata[0].name}.svc.cluster.local"
}

output "postgres_port" {
  description = "PostgreSQL port"
  value       = 5432
}

# -----------------------------------------------------------------------------
# PgBouncer Endpoints (RECOMMENDED for applications)
# -----------------------------------------------------------------------------

output "host" {
  description = "PgBouncer host for read-write connections (use this for apps)"
  value       = "${var.cluster_name}-pooler.${kubernetes_namespace_v1.postgres.metadata[0].name}.svc.cluster.local"
}

output "host_ro" {
  description = "PgBouncer host for read-only connections (use this for read replicas)"
  value       = var.instances > 1 && var.pgbouncer_enable_ro_pooler ? "${var.cluster_name}-pooler-ro.${kubernetes_namespace_v1.postgres.metadata[0].name}.svc.cluster.local" : "${var.cluster_name}-pooler.${kubernetes_namespace_v1.postgres.metadata[0].name}.svc.cluster.local"
}

output "port" {
  description = "PgBouncer port"
  value       = 5432
}

output "pooler_service_rw" {
  description = "PgBouncer read-write service name"
  value       = "${var.cluster_name}-pooler"
}

output "pooler_service_ro" {
  description = "PgBouncer read-only service name"
  value       = var.instances > 1 && var.pgbouncer_enable_ro_pooler ? "${var.cluster_name}-pooler-ro" : "${var.cluster_name}-pooler"
}

# -----------------------------------------------------------------------------
# Credentials
# -----------------------------------------------------------------------------

output "superuser_secret_name" {
  description = "Name of the secret containing superuser credentials"
  value       = "${var.cluster_name}-superuser"
}

output "app_secret_name" {
  description = "Name of the secret containing app user credentials"
  value       = "${var.cluster_name}-app"
}

# -----------------------------------------------------------------------------
# Connection Templates
# -----------------------------------------------------------------------------

output "connection_string_template" {
  description = "Connection string template via PgBouncer (replace PASSWORD and DATABASE)"
  value       = "postgresql://${var.default_user}:PASSWORD@${var.cluster_name}-pooler.${kubernetes_namespace_v1.postgres.metadata[0].name}.svc.cluster.local:5432/DATABASE"
}

output "connection_string_direct_template" {
  description = "Direct connection string template (admin only, replace PASSWORD and DATABASE)"
  value       = "postgresql://${var.default_user}:PASSWORD@${var.cluster_name}-rw.${kubernetes_namespace_v1.postgres.metadata[0].name}.svc.cluster.local:5432/DATABASE"
}

# -----------------------------------------------------------------------------
# PgBouncer Configuration Info
# -----------------------------------------------------------------------------

output "pgbouncer_pool_mode" {
  description = "PgBouncer pool mode"
  value       = var.pgbouncer_pool_mode
}

output "pgbouncer_max_connections" {
  description = "Maximum client connections to PgBouncer"
  value       = var.pgbouncer_max_client_conn
}

output "pgbouncer_instances" {
  description = "Number of PgBouncer instances running"
  value       = var.pgbouncer_instances
}
