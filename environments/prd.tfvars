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

# System node pool - D4s_v5 for production
system_node_pool = {
  vm_size             = "Standard_D4s_v5"
  node_count          = 3
  min_count           = 3
  max_count           = 6
  enable_auto_scaling = true
  zones               = ["1", "2", "3"]
}

# Workload node pools - for application workloads
node_pools = {
  workload = {
    vm_size             = "Standard_D8s_v5"
    node_count          = 3
    min_count           = 3
    max_count           = 10
    enable_auto_scaling = true
    zones               = ["1", "2", "3"]
    node_labels = {
      "workload-type" = "application"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Storage (ZRS for production - zone redundant)
# ─────────────────────────────────────────────────────────────────────────────

storage_account_replication_type = "ZRS"

# ─────────────────────────────────────────────────────────────────────────────
# Workload Identities (none for initial deployment)
# ─────────────────────────────────────────────────────────────────────────────

workload_identities = {}
