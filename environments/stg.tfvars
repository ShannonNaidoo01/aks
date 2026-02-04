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

# System node pool - D2s_v5 for staging
system_node_pool = {
  vm_size             = "Standard_D2s_v5"
  node_count          = 2
  min_count           = 2
  max_count           = 4
  enable_auto_scaling = true
  zones               = ["1", "2", "3"]
}

# Workload node pool - for application workloads
node_pools = {
  workload = {
    vm_size             = "Standard_D4s_v5"
    node_count          = 2
    min_count           = 2
    max_count           = 6
    enable_auto_scaling = true
    zones               = ["1", "2", "3"]
    node_labels = {
      "workload-type" = "application"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Storage (ZRS for staging - mirrors production)
# ─────────────────────────────────────────────────────────────────────────────

storage_account_replication_type = "ZRS"

# ─────────────────────────────────────────────────────────────────────────────
# Workload Identities (none for initial deployment)
# ─────────────────────────────────────────────────────────────────────────────

workload_identities = {}
