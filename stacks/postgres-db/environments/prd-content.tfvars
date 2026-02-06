# -----------------------------------------------------------------------------
# Content Database - Production Environment
# -----------------------------------------------------------------------------

environment        = "prd"
aks_cluster_name   = "prd-aks-cluster"
aks_resource_group = "prd-aks-rg"

# PostgreSQL server reference
postgres_namespace        = "postgres"
postgres_host             = "postgres-cluster-rw.postgres.svc.cluster.local"
pgbouncer_host            = "postgres-cluster-pooler.postgres.svc.cluster.local"
pgbouncer_host_ro         = "postgres-cluster-pooler-ro.postgres.svc.cluster.local"
postgres_superuser_secret = "postgres-cluster-superuser"

# Database configuration
database_name = "content"
database_user = "content_user"
extensions    = ["uuid-ossp", "pgcrypto"]

# Key Vault
key_vault_name = ""
