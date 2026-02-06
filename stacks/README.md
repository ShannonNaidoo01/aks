# Infrastructure Stacks

Each stack has its own state file for isolation and independent deployment.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AKS Cluster (core)                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Ingress   │  │ Cert-Manager│  │   Entra     │  │   Cluster   │        │
│  │   NGINX     │  │             │  │   Groups    │  │    Test     │        │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────┐       │
│  │                 PostgreSQL (postgres-svr)                        │       │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐                       │       │
│  │  │ Primary  │  │ Replica  │  │ Replica  │  (CloudNativePG)      │       │
│  │  │   (RW)   │──│   (RO)   │──│   (RO)   │                       │       │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘                       │       │
│  │       │             └─────┬───────┘                              │       │
│  │       ▼                   ▼                                      │       │
│  │  ┌──────────┐       ┌──────────┐                                │       │
│  │  │PgBouncer │       │PgBouncer │   Connection Pooling           │       │
│  │  │   (RW)   │       │   (RO)   │                                │       │
│  │  └────┬─────┘       └────┬─────┘                                │       │
│  └───────┼──────────────────┼──────────────────────────────────────┘       │
│          │                  │                                               │
│          ▼                  ▼                                               │
│  ┌───────────────────────────────────────┐                                 │
│  │         Databases (postgres-db)        │                                 │
│  │  ┌─────────┐  ┌─────────────────────┐ │                                 │
│  │  │ content │  │      trading        │ │                                 │
│  │  │  (RW)   │  │  (RW + RO replicas) │ │                                 │
│  │  └─────────┘  └─────────────────────┘ │                                 │
│  └───────────────────────────────────────┘                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Structure

```
stacks/
├── core/                       # AKS + ingress + cert-manager
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── environments/
│       ├── dev.tfvars
│       ├── stg.tfvars
│       └── prd.tfvars
│
├── postgres-svr/               # PostgreSQL cluster + PgBouncer
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── environments/
│       ├── dev.tfvars
│       ├── stg.tfvars
│       └── prd.tfvars
│
└── postgres-db/                # Individual databases (per app)
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── environments/
        ├── dev-content.tfvars
        ├── dev-trading.tfvars
        ├── stg-content.tfvars
        ├── stg-trading.tfvars
        ├── prd-content.tfvars
        └── prd-trading.tfvars
```

## Stacks Overview

| Stack | Scope | Description |
|-------|-------|-------------|
| **core** | Environment | AKS cluster, ingress-nginx, cert-manager, entra-groups |
| **postgres-svr** | Environment | PostgreSQL cluster with PgBouncer connection pooling |
| **postgres-db** | Application | Individual databases (content, trading) |

## State Files

| Stack | Container | State Key |
|-------|-----------|-----------|
| core | `core` | `{env}/terraform.tfstate` |
| postgres-svr | `postgres-svr` | `{env}/terraform.tfstate` |
| postgres-db | `postgres-db` | `{env}/{app}/terraform.tfstate` |

Storage Account: `txstate{env}` (e.g., `txstatedev`, `txstatestg`, `txstateprd`)

## PostgreSQL Architecture

### Cluster Configuration by Environment

| Environment | Instances | Replicas | PgBouncer Pods | Max Connections |
|-------------|-----------|----------|----------------|-----------------|
| dev | 1 | 0 | 1 | 500 |
| stg | 2 | 1 | 2 | 750 |
| prd | 3 | 2 | 3 | 2000 |

### Databases

| Database | Purpose | Extensions |
|----------|---------|------------|
| **content** | Content management system | uuid-ossp, pgcrypto |
| **trading** | Trading platform (primary + read replicas) | uuid-ossp, pgcrypto, pg_stat_statements |

### Connection Endpoints

```
# Read-Write (Primary) - via PgBouncer
postgres-cluster-pooler.postgres.svc.cluster.local:5432

# Read-Only (Replicas) - via PgBouncer
postgres-cluster-pooler-ro.postgres.svc.cluster.local:5432

# Direct (Admin only - bypasses PgBouncer)
postgres-cluster-rw.postgres.svc.cluster.local:5432
```

### PgBouncer Configuration

- **Pool Mode**: Transaction (recommended for most apps)
- **Max Client Connections**: 500-2000 depending on environment
- **Default Pool Size**: 10-50 server connections per user/database

## Deployment Order

```
1. core          → AKS cluster foundation
2. postgres-svr  → PostgreSQL + PgBouncer (depends on core)
3. postgres-db   → Databases (depends on postgres-svr)
```

## Usage

### Automatic Deployment (Push)

```bash
# Plan only
git push origin dev

# Plan + Apply
git commit -m "feat: update infrastructure [tfapply]"
git push origin dev
```

**Note**: Auto-deploy only triggers for environment-scope stacks (core, postgres-svr).
For databases (postgres-db), use manual deployment.

### Manual Deployment (Workflow Dispatch)

Go to **Actions → Infrastructure as Code**

#### Deploy Core or PostgreSQL Server

| Field | Value |
|-------|-------|
| Environment | `dev` / `stg` / `prd` |
| Stack | `core` / `postgres-svr` / `all` |
| App name | *(leave empty)* |
| Action | `plan` / `apply` |

#### Deploy Database

| Field | Value |
|-------|-------|
| Environment | `dev` / `stg` / `prd` |
| Stack | `postgres-db` |
| App name | `content` / `trading` |
| Action | `plan` / `apply` |

## Adding a New Database

1. **Create tfvars file**:
   ```bash
   cp stacks/postgres-db/environments/dev-content.tfvars \
      stacks/postgres-db/environments/dev-newapp.tfvars
   ```

2. **Edit the configuration**:
   ```hcl
   # stacks/postgres-db/environments/dev-newapp.tfvars
   environment        = "dev"
   aks_cluster_name   = "dev-aks-cluster"
   aks_resource_group = "dev-aks-rg"

   postgres_namespace        = "postgres"
   postgres_host             = "postgres-cluster-rw.postgres.svc.cluster.local"
   pgbouncer_host            = "postgres-cluster-pooler.postgres.svc.cluster.local"
   pgbouncer_host_ro         = "postgres-cluster-pooler-ro.postgres.svc.cluster.local"
   postgres_superuser_secret = "postgres-cluster-superuser"

   database_name = "newapp"
   database_user = "newapp_user"
   extensions    = ["uuid-ossp"]
   ```

3. **Deploy**:
   - Stack: `postgres-db`
   - App name: `newapp`
   - Action: `plan` → `apply`

4. **Repeat for stg/prd** when ready.

## Application Connection

Each database gets a Kubernetes Secret with connection details:

```yaml
# Secret: {database}-db-credentials
data:
  username: trading_user
  password: <generated>
  database: trading
  host: postgres-cluster-pooler.postgres.svc.cluster.local     # RW
  host_ro: postgres-cluster-pooler-ro.postgres.svc.cluster.local  # RO
  uri: postgresql://trading_user:***@pooler:5432/trading       # RW
  uri_ro: postgresql://trading_user:***@pooler-ro:5432/trading # RO
  host_direct: postgres-cluster-rw.postgres.svc.cluster.local  # Admin only
```

**Recommendation**: Always use `host` / `uri` (PgBouncer) for applications. Use `host_direct` only for migrations or admin tasks.

## Azure Setup

Create storage containers for state files:

```bash
# For each environment (dev, stg, prd)
for ENV in dev stg prd; do
  az storage container create --name core --account-name txstate${ENV}
  az storage container create --name postgres-svr --account-name txstate${ENV}
  az storage container create --name postgres-db --account-name txstate${ENV}
done
```

## GitHub Secrets Required

| Secret | Description |
|--------|-------------|
| `ARM_CLIENT_ID` | Azure Service Principal Client ID |
| `ARM_CLIENT_SECRET` | Azure Service Principal Secret |
| `ARM_SUBSCRIPTION_ID` | Azure Subscription ID |
| `ARM_TENANT_ID` | Azure Tenant ID |
| `STATE_ACCESS_KEY` | Storage Account Access Key |

## Benefits

- **Isolation** - Each stack has independent state
- **Safety** - Smaller blast radius per deployment
- **Speed** - Plan only what changed
- **Parallelism** - Teams can work on different stacks
- **Connection Pooling** - PgBouncer handles 1000s of connections efficiently
- **Read Scaling** - Separate pooler for read replicas
- **Per-App State** - Each database has independent lifecycle
