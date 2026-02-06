# -----------------------------------------------------------------------------
# Content Database - Dev Environment
# -----------------------------------------------------------------------------
# For content management system data
# Deploy: workflow_dispatch → stack: postgres-db, app_name: content
# -----------------------------------------------------------------------------

environment        = "dev"
aks_cluster_name   = "dev-aks-cluster"
aks_resource_group = "dev-aks-rg"

# PostgreSQL server reference
postgres_namespace        = "postgres"
postgres_host             = "postgres-cluster-rw.postgres.svc.cluster.local"
pgbouncer_host            = "postgres-cluster-pooler.postgres.svc.cluster.local"
postgres_superuser_secret = "postgres-cluster-superuser"

# Database configuration
database_name = "content"
database_user = "content_user"
extensions    = ["uuid-ossp", "pgcrypto"]

# Key Vault (optional)
key_vault_name = ""
