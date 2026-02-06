# -----------------------------------------------------------------------------
# Staging PostgreSQL Server Configuration
# -----------------------------------------------------------------------------

environment        = "stg"
aks_cluster_name   = "stg-aks-cluster"
aks_resource_group = "stg-aks-rg"

# PostgreSQL Cluster
namespace    = "postgres"
cluster_name = "postgres-cluster"
instances    = 2
storage_size = "20Gi"

# PostgreSQL Resources
cpu_request    = "250m"
cpu_limit      = "1000m"
memory_request = "512Mi"
memory_limit   = "1Gi"

# PostgreSQL Parameters
max_connections = 100
shared_buffers  = "256MB"

# PgBouncer Configuration
pgbouncer_instances         = 2
pgbouncer_pool_mode         = "transaction"
pgbouncer_max_client_conn   = 750
pgbouncer_default_pool_size = 20
pgbouncer_enable_ro_pooler  = true  # Enable for read replicas

# Backups
enable_backups = false  # Enable when backup storage is configured

# Monitoring
enable_monitoring = true
