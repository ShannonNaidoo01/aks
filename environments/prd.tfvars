# ═══════════════════════════════════════════════════════════════════════════════
# Production Environment Configuration
# ═══════════════════════════════════════════════════════════════════════════════

environment        = "prd"
location           = "uksouth"
kubernetes_version = "1.32"

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
# ─────────────────────────────────────────────────────────────────────────────

# System node pool - B2s for production (quota friendly)
# TODO: Upgrade to D-series VMs after requesting quota increase
system_node_pool = {
  vm_size             = "Standard_B2s"
  node_count          = 1
  min_count           = 1
  max_count           = 3
  enable_auto_scaling = true
  zones               = [] # B-series doesn't support zones
}

# No additional node pools (quota constraints)
# TODO: Add workload pools after requesting quota increase
node_pools = {}

# ─────────────────────────────────────────────────────────────────────────────
# Storage (ZRS for production - zone redundant)
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
