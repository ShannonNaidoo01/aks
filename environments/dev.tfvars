# ═══════════════════════════════════════════════════════════════════════════════
# Development Environment Configuration
# ═══════════════════════════════════════════════════════════════════════════════

environment        = "dev"
location           = "uksouth"
kubernetes_version = "1.32"

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

# System node pool - B2s for dev (quota friendly)
system_node_pool = {
  vm_size             = "Standard_B2s"
  node_count          = 1
  min_count           = 1
  max_count           = 3
  enable_auto_scaling = true
  zones               = [] # B-series doesn't support zones
}

# No additional node pools for dev (keep costs low, avoid quota issues)
node_pools = {}

# ─────────────────────────────────────────────────────────────────────────────
# Storage (LRS for dev, use ZRS for production)
# ─────────────────────────────────────────────────────────────────────────────

storage_account_replication_type = "LRS"

# ─────────────────────────────────────────────────────────────────────────────
# Workload Identities (none for initial deployment)
# ─────────────────────────────────────────────────────────────────────────────

workload_identities = {}
