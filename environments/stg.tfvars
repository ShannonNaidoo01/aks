# ═══════════════════════════════════════════════════════════════════════════════
# Staging Environment Configuration
# ═══════════════════════════════════════════════════════════════════════════════

environment        = "stg"
location           = "uksouth"
kubernetes_version = "1.32"

tags = {
  project     = "tune-exchange"
  cost_center = "staging"
}

# ─────────────────────────────────────────────────────────────────────────────
# AKS Cluster (Standard tier for staging - mirrors production)
# ─────────────────────────────────────────────────────────────────────────────

aks_sku_tier = "Standard"

# ─────────────────────────────────────────────────────────────────────────────
# Node Pools
# ─────────────────────────────────────────────────────────────────────────────

# System node pool - B2s for staging (quota friendly)
system_node_pool = {
  vm_size             = "Standard_B2s"
  node_count          = 1
  min_count           = 1
  max_count           = 3
  enable_auto_scaling = true
  zones               = [] # B-series doesn't support zones
}

# No additional node pools (quota constraints)
node_pools = {}

# ─────────────────────────────────────────────────────────────────────────────
# Storage (ZRS for staging - mirrors production)
# ─────────────────────────────────────────────────────────────────────────────

storage_account_replication_type = "ZRS"

# ─────────────────────────────────────────────────────────────────────────────
# Workload Identities (none for initial deployment)
# ─────────────────────────────────────────────────────────────────────────────

workload_identities = {}

# ─────────────────────────────────────────────────────────────────────────────
# Cert-Manager
# ─────────────────────────────────────────────────────────────────────────────

enable_cert_manager  = true
cert_manager_version = "v1.14.3"
letsencrypt_email    = "" # Set to enable Let's Encrypt issuers
