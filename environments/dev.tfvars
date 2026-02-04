# ═══════════════════════════════════════════════════════════════════════════════
# Development Environment Configuration
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

# System node pool - uses defaults (Standard_D2s_v5, 2 nodes, zones 1,2,3)
system_node_pool = {
  max_count = 3  # Override: limit to 3 for dev
}

# Workload node pool - for application workloads
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
# Workload Identities (none for initial deployment)
# ─────────────────────────────────────────────────────────────────────────────

workload_identities = {}
