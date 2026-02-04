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

kubernetes_version      = "1.29"
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
# Node Pools (smaller for dev)
# ─────────────────────────────────────────────────────────────────────────────

system_node_pool = {
  name                = "system"
  vm_size             = "Standard_D2s_v5"
  node_count          = 1
  min_count           = 1
  max_count           = 3
  os_disk_size_gb     = 50
  enable_auto_scaling = true
  zones               = ["1"]
}

node_pools = {
  webapps = {
    vm_size             = "Standard_D2s_v5"
    node_count          = 1
    min_count           = 1
    max_count           = 3
    os_disk_size_gb     = 50
    enable_auto_scaling = true
    node_labels = {
      "workload-type" = "web"
    }
    node_taints = []
  }
  postgres = {
    vm_size             = "Standard_D4s_v5"
    node_count          = 1
    min_count           = 1
    max_count           = 2
    os_disk_size_gb     = 100
    enable_auto_scaling = true
    ultra_ssd_enabled   = false
    node_labels = {
      "workload-type" = "database"
    }
    node_taints = ["workload=postgres:NoSchedule"]
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Storage
# ─────────────────────────────────────────────────────────────────────────────

storage_account_tier             = "Standard"
storage_account_replication_type = "LRS"

storage_containers = [
  { name = "data" },
  { name = "backups" }
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

workload_identities = {
  storage-access = {
    namespace       = "default"
    service_account = "storage-sa"
    description     = "Identity for applications accessing Azure Storage"
  }
  postgres-access = {
    namespace       = "postgres"
    service_account = "postgres-sa"
    description     = "Identity for PostgreSQL workloads"
  }
}
