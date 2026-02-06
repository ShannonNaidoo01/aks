# -----------------------------------------------------------------------------
# Dev PostgreSQL Server Configuration
# -----------------------------------------------------------------------------

environment        = "dev"
aks_cluster_name   = "dev-aks-cluster"
aks_resource_group = "dev-aks-rg"

# PostgreSQL Cluster
namespace    = "postgres"
cluster_name = "postgres-cluster"
instances    = 1
storage_size = "10Gi"

# PostgreSQL Resources (minimal for dev)
cpu_request    = "100m"
cpu_limit      = "500m"
memory_request = "256Mi"
memory_limit   = "512Mi"

# PostgreSQL Parameters
max_connections = 50
shared_buffers  = "128MB"

# PgBouncer Configuration
pgbouncer_instances         = 1          # Single instance for dev
pgbouncer_pool_mode         = "transaction"
pgbouncer_max_client_conn   = 500        # Lower for dev
pgbouncer_default_pool_size = 10
pgbouncer_enable_ro_pooler  = false      # No read replicas in dev

# Backups disabled for dev
enable_backups = false

# Monitoring disabled for dev
enable_monitoring = false
