# ═══════════════════════════════════════════════════════════════════════════════
# Development Environment Configuration
# ═══════════════════════════════════════════════════════════════════════════════

environment = "dev"
location    = "uksouth"

tags = {
  project     = "aks-cluster"
  cost_center = "development"
}

# ─────────────────────────────────────────────────────────────────────────────
# AKS Cluster
# ─────────────────────────────────────────────────────────────────────────────

kubernetes_version      = "1.32"
aks_sku_tier            = "Free"
private_cluster_enabled = false

# ─────────────────────────────────────────────────────────────────────────────
# Network
# ─────────────────────────────────────────────────────────────────────────────

vnet_address_space        = ["10.0.0.0/16"]
aks_subnet_address_prefix = "10.0.0.0/20"
service_cidr              = "10.1.0.0/16"
dns_service_ip            = "10.1.0.10"

# ─────────────────────────────────────────────────────────────────────────────
# Node Pools
# ─────────────────────────────────────────────────────────────────────────────

system_node_pool = {
  name                = "system"
  vm_size             = "Standard_B2s"
  node_count          = 1
  min_count           = 1
  max_count           = 3
  os_disk_size_gb     = 50
  enable_auto_scaling = true
  zones               = [] # B-series doesn't support zones
}

# No additional node pools for dev (keep costs low)
node_pools = {}

# ─────────────────────────────────────────────────────────────────────────────
# Storage
# ─────────────────────────────────────────────────────────────────────────────

storage_account_tier             = "Standard"
storage_account_replication_type = "LRS"

storage_containers = [
  { name = "data" }
]

# ─────────────────────────────────────────────────────────────────────────────
# Key Vault
# ─────────────────────────────────────────────────────────────────────────────

key_vault_sku = "standard"

# ─────────────────────────────────────────────────────────────────────────────
# RBAC
# ─────────────────────────────────────────────────────────────────────────────

admin_group_object_ids = []
azure_rbac_enabled     = true

# ─────────────────────────────────────────────────────────────────────────────
# Workload Identities
# ─────────────────────────────────────────────────────────────────────────────

workload_identities = {}
