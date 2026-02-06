# -----------------------------------------------------------------------------
# Production PostgreSQL Server Configuration
# -----------------------------------------------------------------------------

environment        = "prd"
aks_cluster_name   = "prd-aks-cluster"
aks_resource_group = "prd-aks-rg"

# PostgreSQL Cluster
namespace    = "postgres"
cluster_name = "postgres-cluster"
instances    = 3
storage_size = "50Gi"

# PostgreSQL Resources
cpu_request    = "500m"
cpu_limit      = "2000m"
memory_request = "1Gi"
memory_limit   = "2Gi"

# PostgreSQL Parameters
max_connections = 200
shared_buffers  = "512MB"

# PgBouncer Configuration
pgbouncer_instances         = 3 # HA for production
pgbouncer_pool_mode         = "transaction"
pgbouncer_max_client_conn   = 2000 # High capacity for prod
pgbouncer_default_pool_size = 50
pgbouncer_enable_ro_pooler  = true # Enable for read replicas

# Backups
enable_backups = false # Enable when backup storage is configured

# Monitoring
enable_monitoring = true
