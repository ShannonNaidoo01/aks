# ═══════════════════════════════════════════════════════════════════════════════
# Production Environment Configuration - Core Stack
# ═══════════════════════════════════════════════════════════════════════════════

environment = "prd"

tags = {
  project     = "tune-exchange"
  cost_center = "production"
}

# ─────────────────────────────────────────────────────────────────────────────
# AKS Cluster (Standard tier for production SLA)
# ─────────────────────────────────────────────────────────────────────────────

aks_sku_tier = "Standard"

# ─────────────────────────────────────────────────────────────────────────────
# Node Pools
# TODO: Upgrade to D-series VMs after requesting quota increase
# ─────────────────────────────────────────────────────────────────────────────

system_node_pool = {
  vm_size             = "Standard_B2s"
  node_count          = 1
  min_count           = 1
  max_count           = 3
  enable_auto_scaling = true
  zones               = []
}

node_pools = {}

# ─────────────────────────────────────────────────────────────────────────────
# Storage (ZRS for production - zone redundant)
# ─────────────────────────────────────────────────────────────────────────────

storage_account_replication_type = "ZRS"

# ─────────────────────────────────────────────────────────────────────────────
# Workload Identities
# ─────────────────────────────────────────────────────────────────────────────

workload_identities = {}

# ─────────────────────────────────────────────────────────────────────────────
# Ingress Controller
# ─────────────────────────────────────────────────────────────────────────────

enable_ingress_nginx        = true
ingress_nginx_replica_count = 3 # Higher HA for production
ingress_nginx_internal_lb   = false

# ─────────────────────────────────────────────────────────────────────────────
# Cert-Manager
# ─────────────────────────────────────────────────────────────────────────────

enable_cert_manager              = true
letsencrypt_email                = ""
cert_manager_self_signed_issuer  = true
cert_manager_letsencrypt_issuers = true

# ─────────────────────────────────────────────────────────────────────────────
# Cluster Test App
# ─────────────────────────────────────────────────────────────────────────────

enable_cluster_test = false

# ─────────────────────────────────────────────────────────────────────────────
# Azure Entra Groups
# ─────────────────────────────────────────────────────────────────────────────

enable_entra_groups = false
