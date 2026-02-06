# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------

output "database_name" {
  description = "The database name"
  value       = module.postgres_database.database_name
}

output "database_user" {
  description = "The database user"
  value       = module.postgres_database.database_user
}

output "credentials_secret" {
  description = "Kubernetes secret containing credentials"
  value = {
    name      = module.postgres_database.credentials_secret_name
    namespace = module.postgres_database.credentials_secret_namespace
  }
}

output "connection_info" {
  description = "Database connection information"
  value = {
    host     = module.postgres_database.host
    port     = module.postgres_database.port
    database = module.postgres_database.database_name
    user     = module.postgres_database.database_user
  }
}
