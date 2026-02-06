# -----------------------------------------------------------------------------
# Trading Database - Dev Environment
# -----------------------------------------------------------------------------
# Primary trading database - connects via PgBouncer for connection pooling
# Read replicas accessed via: postgres-cluster-pooler-ro service
#
# Deploy: workflow_dispatch → stack: postgres-db, app_name: trading
# -----------------------------------------------------------------------------

environment        = "dev"
aks_cluster_name   = "dev-aks-cluster"
aks_resource_group = "dev-aks-rg"

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

# Key Vault (optional)
key_vault_name = ""
