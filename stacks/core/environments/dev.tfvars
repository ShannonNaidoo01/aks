# ═══════════════════════════════════════════════════════════════════════════════
# Development Environment Configuration - Core Stack
# ═══════════════════════════════════════════════════════════════════════════════

environment = "dev"

tags = {
  project     = "tune-exchange"
  cost_center = "development"
}

# ─────────────────────────────────────────────────────────────────────────────
# AKS Cluster (Free tier for dev, use Standard for production)
# ─────────────────────────────────────────────────────────────────────────────

aks_sku_tier = "Free"

# ─────────────────────────────────────────────────────────────────────────────
# Node Pools
# ─────────────────────────────────────────────────────────────────────────────

system_node_pool = {
  max_count = 3
}

node_pools = {
  workload = {
    vm_size   = "Standard_D4s_v5"
    max_count = 5
    node_labels = {
      "workload-type" = "application"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Storage (LRS for dev, use ZRS for production)
# ─────────────────────────────────────────────────────────────────────────────

storage_account_replication_type = "LRS"

# ─────────────────────────────────────────────────────────────────────────────
# Workload Identities
# ─────────────────────────────────────────────────────────────────────────────

workload_identities = {}

# ─────────────────────────────────────────────────────────────────────────────
# Ingress Controller
# ─────────────────────────────────────────────────────────────────────────────

enable_ingress_nginx             = true
ingress_nginx_replica_count      = 2
ingress_nginx_internal_lb        = false
ingress_nginx_default_ssl_secret = "wildcard-dev-tune-exchange-tls"

# ─────────────────────────────────────────────────────────────────────────────
# Cert-Manager
# ─────────────────────────────────────────────────────────────────────────────

enable_cert_manager              = true
letsencrypt_email                = "bob@tune.exchange"
cert_manager_self_signed_issuer  = true
cert_manager_letsencrypt_issuers = true

# ─────────────────────────────────────────────────────────────────────────────
# DNS Zones (disabled - enable when DNS is configured)
# ─────────────────────────────────────────────────────────────────────────────

existing_dns_zones = {}

# existing_dns_zones = {
#   dev = {
#     name                = "dev.tune.exchange"
#     resource_group_name = "dev-dns-rg"
#   }
# }

# ─────────────────────────────────────────────────────────────────────────────
# Wildcard Certificates (disabled - enable when DNS is configured)
# ─────────────────────────────────────────────────────────────────────────────

wildcard_certificates = {}

# wildcard_certificates = {
#   wildcard-dev = {
#     dns_name         = "*.dev.tune.exchange"
#     issuer_name      = "letsencrypt-dns-prod"
#     secret_name      = "wildcard-dev-tune-exchange-tls"
#     target_namespace = "ingress-nginx"
#   }
# }

# ─────────────────────────────────────────────────────────────────────────────
# Cluster Test App
# ─────────────────────────────────────────────────────────────────────────────

enable_cluster_test   = true
cluster_test_hostname = "cluster-test.dev.tune.exchange"

# ─────────────────────────────────────────────────────────────────────────────
# Azure Entra Groups
# ─────────────────────────────────────────────────────────────────────────────

enable_entra_groups = false
