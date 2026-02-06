# -----------------------------------------------------------------------------
# PostgreSQL Server Module (Environment Scope)
# -----------------------------------------------------------------------------
# Deploys CloudNativePG operator, PostgreSQL cluster, and PgBouncer pooler.
# Deploy once per environment.
# -----------------------------------------------------------------------------

terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    time = {
      source = "hashicorp/time"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

# -----------------------------------------------------------------------------
# Namespace
# -----------------------------------------------------------------------------
resource "kubernetes_namespace_v1" "postgres" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/name"       = "postgres"
      "app.kubernetes.io/component"  = "database"
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
    }
  }
}

# -----------------------------------------------------------------------------
# CloudNativePG Operator (via Helm)
# -----------------------------------------------------------------------------
resource "helm_release" "cloudnative_pg" {
  name       = "cloudnative-pg"
  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "cloudnative-pg"
  version    = var.operator_version
  namespace  = kubernetes_namespace_v1.postgres.metadata[0].name

  set {
    name  = "replicaCount"
    value = "1"
  }

  set {
    name  = "monitoring.podMonitorEnabled"
    value = var.enable_monitoring
  }

  wait    = true
  timeout = 600
}

# Wait for operator to be ready
resource "time_sleep" "wait_for_operator" {
  depends_on      = [helm_release.cloudnative_pg]
  create_duration = "30s"
}

# -----------------------------------------------------------------------------
# PostgreSQL Cluster (via kubectl manifest)
# -----------------------------------------------------------------------------
resource "kubectl_manifest" "postgres_cluster" {
  depends_on = [time_sleep.wait_for_operator]

  yaml_body = yamlencode({
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"
    metadata = {
      name      = var.cluster_name
      namespace = kubernetes_namespace_v1.postgres.metadata[0].name
      labels = {
        "app.kubernetes.io/name"       = var.cluster_name
        "app.kubernetes.io/component"  = "database"
        "app.kubernetes.io/managed-by" = "terraform"
        "environment"                  = var.environment
      }
    }
    spec = {
      instances = var.instances
      imageName = "ghcr.io/cloudnative-pg/postgresql:${var.postgres_version}"

      # Bootstrap configuration
      bootstrap = {
        initdb = {
          database      = var.default_database
          owner         = var.default_user
          encoding      = "UTF8"
          localeCType   = "C"
          localeCollate = "C"
        }
      }

      # PostgreSQL configuration
      postgresql = {
        parameters = {
          max_connections                  = tostring(var.max_connections)
          shared_buffers                   = var.shared_buffers
          effective_cache_size             = var.effective_cache_size
          maintenance_work_mem             = var.maintenance_work_mem
          checkpoint_completion_target     = "0.9"
          wal_buffers                      = "16MB"
          default_statistics_target        = "100"
          random_page_cost                 = "1.1"
          effective_io_concurrency         = "200"
          min_wal_size                     = "1GB"
          max_wal_size                     = "4GB"
          max_worker_processes             = "4"
          max_parallel_workers_per_gather  = "2"
          max_parallel_workers             = "4"
          max_parallel_maintenance_workers = "2"
          # PgBouncer friendly settings
          tcp_keepalives_idle     = "600"
          tcp_keepalives_interval = "30"
          tcp_keepalives_count    = "10"
        }
        pg_hba = [
          "host all all 10.0.0.0/8 scram-sha-256",
          "host all all 172.16.0.0/12 scram-sha-256",
          "host all all 192.168.0.0/16 scram-sha-256"
        ]
      }

      # Storage
      storage = {
        size         = var.storage_size
        storageClass = var.storage_class
      }

      # Resources
      resources = {
        requests = {
          cpu    = var.cpu_request
          memory = var.memory_request
        }
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
      }

      # High availability
      primaryUpdateStrategy = "unsupervised"
      primaryUpdateMethod   = "switchover"

      # Monitoring
      monitoring = var.enable_monitoring ? {
        enablePodMonitor = true
      } : null

      # Backup (if enabled)
      backup = var.enable_backups ? {
        barmanObjectStore = {
          destinationPath = "s3://${var.backup_bucket}/${var.cluster_name}"
          endpointURL     = var.backup_endpoint
          s3Credentials = {
            accessKeyId = {
              name = "${var.cluster_name}-backup-creds"
              key  = "ACCESS_KEY_ID"
            }
            secretAccessKey = {
              name = "${var.cluster_name}-backup-creds"
              key  = "SECRET_ACCESS_KEY"
            }
          }
          wal = {
            compression = "gzip"
          }
          data = {
            compression = "gzip"
          }
        }
        retentionPolicy = var.backup_retention
      } : null
    }
  })
}

# Wait for cluster to be ready
resource "time_sleep" "wait_for_cluster" {
  depends_on      = [kubectl_manifest.postgres_cluster]
  create_duration = "60s"
}

# -----------------------------------------------------------------------------
# PgBouncer Pooler (Connection Pooling)
# -----------------------------------------------------------------------------
resource "kubectl_manifest" "pgbouncer_pooler" {
  depends_on = [time_sleep.wait_for_cluster]

  yaml_body = yamlencode({
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Pooler"
    metadata = {
      name      = "${var.cluster_name}-pooler"
      namespace = kubernetes_namespace_v1.postgres.metadata[0].name
      labels = {
        "app.kubernetes.io/name"       = "${var.cluster_name}-pooler"
        "app.kubernetes.io/component"  = "connection-pooler"
        "app.kubernetes.io/managed-by" = "terraform"
        "environment"                  = var.environment
      }
    }
    spec = {
      # Reference the cluster
      cluster = {
        name = var.cluster_name
      }

      # Number of PgBouncer instances
      instances = var.pgbouncer_instances

      # Pool type: rw (read-write) or ro (read-only)
      type = "rw"

      # PgBouncer configuration
      pgbouncer = {
        # Pool mode: session, transaction, or statement
        poolMode = var.pgbouncer_pool_mode

        # Parameters
        parameters = {
          # Connection limits
          max_client_conn      = tostring(var.pgbouncer_max_client_conn)
          default_pool_size    = tostring(var.pgbouncer_default_pool_size)
          min_pool_size        = tostring(var.pgbouncer_min_pool_size)
          reserve_pool_size    = tostring(var.pgbouncer_reserve_pool_size)
          reserve_pool_timeout = tostring(var.pgbouncer_reserve_pool_timeout)

          # Timeouts
          server_idle_timeout  = "600"
          server_lifetime      = "3600"
          client_idle_timeout  = "0"
          client_login_timeout = "60"
          query_timeout        = "0"
          query_wait_timeout   = "120"

          # Logging
          log_connections    = "1"
          log_disconnections = "1"
          log_pooler_errors  = "1"
          stats_period       = "60"

          # Security
          ignore_startup_parameters = "extra_float_digits,options"
        }

        # Auth query for user validation
        authQuerySecret = {
          name = "${var.cluster_name}-superuser"
        }
        authQuery = "SELECT usename, passwd FROM pg_shadow WHERE usename=$1"
      }

      # Resources for PgBouncer pods
      template = {
        spec = {
          containers = [
            {
              name = "pgbouncer"
              resources = {
                requests = {
                  cpu    = var.pgbouncer_cpu_request
                  memory = var.pgbouncer_memory_request
                }
                limits = {
                  cpu    = var.pgbouncer_cpu_limit
                  memory = var.pgbouncer_memory_limit
                }
              }
            }
          ]
        }
      }

      # Monitoring
      monitoring = var.enable_monitoring ? {
        enablePodMonitor = true
      } : null
    }
  })
}

# -----------------------------------------------------------------------------
# Read-Only Pooler (Optional - for read replicas)
# -----------------------------------------------------------------------------
resource "kubectl_manifest" "pgbouncer_pooler_ro" {
  count      = var.instances > 1 && var.pgbouncer_enable_ro_pooler ? 1 : 0
  depends_on = [time_sleep.wait_for_cluster]

  yaml_body = yamlencode({
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Pooler"
    metadata = {
      name      = "${var.cluster_name}-pooler-ro"
      namespace = kubernetes_namespace_v1.postgres.metadata[0].name
      labels = {
        "app.kubernetes.io/name"       = "${var.cluster_name}-pooler-ro"
        "app.kubernetes.io/component"  = "connection-pooler-readonly"
        "app.kubernetes.io/managed-by" = "terraform"
        "environment"                  = var.environment
      }
    }
    spec = {
      cluster = {
        name = var.cluster_name
      }
      instances = var.pgbouncer_instances
      type      = "ro"

      pgbouncer = {
        poolMode = var.pgbouncer_pool_mode
        parameters = {
          max_client_conn     = tostring(var.pgbouncer_max_client_conn)
          default_pool_size   = tostring(var.pgbouncer_default_pool_size)
          min_pool_size       = tostring(var.pgbouncer_min_pool_size)
          reserve_pool_size   = tostring(var.pgbouncer_reserve_pool_size)
          server_idle_timeout = "600"
          server_lifetime     = "3600"
          log_connections     = "1"
          log_disconnections  = "1"
        }
        authQuerySecret = {
          name = "${var.cluster_name}-superuser"
        }
        authQuery = "SELECT usename, passwd FROM pg_shadow WHERE usename=$1"
      }

      template = {
        spec = {
          containers = [
            {
              name = "pgbouncer"
              resources = {
                requests = {
                  cpu    = var.pgbouncer_cpu_request
                  memory = var.pgbouncer_memory_request
                }
                limits = {
                  cpu    = var.pgbouncer_cpu_limit
                  memory = var.pgbouncer_memory_limit
                }
              }
            }
          ]
        }
      }

      monitoring = var.enable_monitoring ? {
        enablePodMonitor = true
      } : null
    }
  })
}
