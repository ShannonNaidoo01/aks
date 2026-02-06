# -----------------------------------------------------------------------------
# Trading Database - Production Environment
# -----------------------------------------------------------------------------
# Read replicas: postgres-cluster-pooler-ro (3 replicas in production)
# High-performance trading workload with read scaling
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
database_name = "trading"
database_user = "trading_user"
extensions    = ["uuid-ossp", "pgcrypto", "pg_stat_statements"]

# Key Vault
key_vault_name = ""
