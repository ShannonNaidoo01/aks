# -----------------------------------------------------------------------------
# PostgreSQL Database Module (Application Scope)
# -----------------------------------------------------------------------------
# Creates databases on an existing PostgreSQL cluster.
# Deploy once per application that needs a database.
# -----------------------------------------------------------------------------

# Provider source for kubectl
terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

# -----------------------------------------------------------------------------
# Database User Secret
# -----------------------------------------------------------------------------
resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_secret_v1" "db_credentials" {
  metadata {
    name      = "${var.database_name}-db-credentials"
    namespace = var.postgres_namespace

    labels = {
      "app.kubernetes.io/name"       = var.database_name
      "app.kubernetes.io/component"  = "database"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  data = {
    username = var.database_user
    password = random_password.db_password.result
    database = var.database_name
    # PgBouncer endpoint - READ/WRITE (recommended for apps)
    host = var.pgbouncer_host
    port = "5432"
    uri  = "postgresql://${var.database_user}:${random_password.db_password.result}@${var.pgbouncer_host}:5432/${var.database_name}"
    # PgBouncer endpoint - READ ONLY (for read replicas)
    host_ro = var.pgbouncer_host_ro != "" ? var.pgbouncer_host_ro : var.pgbouncer_host
    uri_ro  = "postgresql://${var.database_user}:${random_password.db_password.result}@${var.pgbouncer_host_ro != "" ? var.pgbouncer_host_ro : var.pgbouncer_host}:5432/${var.database_name}"
    # Direct PostgreSQL endpoint (for admin/migration tasks)
    host_direct = var.postgres_host
    uri_direct  = "postgresql://${var.database_user}:${random_password.db_password.result}@${var.postgres_host}:5432/${var.database_name}"
  }

  type = "Opaque"
}

# -----------------------------------------------------------------------------
# Database Creation Job
# -----------------------------------------------------------------------------
resource "kubernetes_job_v1" "create_database" {
  metadata {
    name      = "create-db-${var.database_name}"
    namespace = var.postgres_namespace

    labels = {
      "app.kubernetes.io/name"       = var.database_name
      "app.kubernetes.io/component"  = "database-init"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    ttl_seconds_after_finished = 300
    backoff_limit              = 3

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = var.database_name
        }
      }

      spec {
        restart_policy = "OnFailure"

        container {
          name  = "create-db"
          image = "postgres:15-alpine"

          command = ["/bin/sh", "-c"]
          args = [<<-EOT
            set -e
            echo "Connecting to PostgreSQL..."
            
            # Wait for PostgreSQL to be ready
            until pg_isready -h $PGHOST -U $SUPERUSER; do
              echo "Waiting for PostgreSQL..."
              sleep 2
            done
            
            echo "Creating database ${var.database_name}..."
            
            # Create user if not exists
            psql -h $PGHOST -U $SUPERUSER -d postgres -c \
              "DO \$\$ BEGIN CREATE USER ${var.database_user} WITH PASSWORD '$DB_PASSWORD'; EXCEPTION WHEN duplicate_object THEN NULL; END \$\$;"
            
            # Create database if not exists
            psql -h $PGHOST -U $SUPERUSER -d postgres -c \
              "SELECT 'CREATE DATABASE ${var.database_name} OWNER ${var.database_user}' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${var.database_name}')\gexec"
            
            # Grant privileges
            psql -h $PGHOST -U $SUPERUSER -d ${var.database_name} -c \
              "GRANT ALL PRIVILEGES ON DATABASE ${var.database_name} TO ${var.database_user};"
            
            psql -h $PGHOST -U $SUPERUSER -d ${var.database_name} -c \
              "GRANT ALL ON SCHEMA public TO ${var.database_user};"
            
            # Install extensions if specified
            %{for ext in var.extensions~}
            psql -h $PGHOST -U $SUPERUSER -d ${var.database_name} -c "CREATE EXTENSION IF NOT EXISTS ${ext};"
            %{endfor~}
            
            echo "Database ${var.database_name} created successfully!"
          EOT
          ]

          env {
            name  = "PGHOST"
            value = var.postgres_host
          }

          env {
            name = "SUPERUSER"
            value_from {
              secret_key_ref {
                name = var.postgres_superuser_secret
                key  = "username"
              }
            }
          }

          env {
            name = "PGPASSWORD"
            value_from {
              secret_key_ref {
                name = var.postgres_superuser_secret
                key  = "password"
              }
            }
          }

          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.db_credentials.metadata[0].name
                key  = "password"
              }
            }
          }
        }
      }
    }
  }

  wait_for_completion = true

  timeouts {
    create = "5m"
  }

  depends_on = [kubernetes_secret_v1.db_credentials]
}

# -----------------------------------------------------------------------------
# Optional: Store credentials in Key Vault
# -----------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "db_connection_string" {
  count = var.key_vault_id != "" ? 1 : 0

  name         = "${var.database_name}-db-connection"
  value        = "postgresql://${var.database_user}:${random_password.db_password.result}@${var.pgbouncer_host}:5432/${var.database_name}"
  key_vault_id = var.key_vault_id

  tags = {
    database   = var.database_name
    managed    = "terraform"
    connection = "pgbouncer"
  }
}

resource "azurerm_key_vault_secret" "db_connection_string_direct" {
  count = var.key_vault_id != "" ? 1 : 0

  name         = "${var.database_name}-db-connection-direct"
  value        = "postgresql://${var.database_user}:${random_password.db_password.result}@${var.postgres_host}:5432/${var.database_name}"
  key_vault_id = var.key_vault_id

  tags = {
    database   = var.database_name
    managed    = "terraform"
    connection = "direct"
  }
}
