# Cert-Manager Helm Module

Terraform module to deploy [cert-manager](https://cert-manager.io/) on Kubernetes with pre-configured ClusterIssuers for automated TLS certificate management.

## Overview

This module deploys:

- **cert-manager** via Helm chart from Jetstack repository
- **Self-Signed ClusterIssuer** for internal/development certificates
- **Let's Encrypt Staging ClusterIssuer** for testing (not trusted by browsers)
- **Let's Encrypt Production ClusterIssuer** for real certificates (trusted)

## How It Works

### Certificate Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         TLS Certificate Automation                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. Ingress Created                 2. Cert-Manager Detects                 │
│  ┌──────────────────────┐          ┌──────────────────────┐                │
│  │ apiVersion: networking│          │ Watches for Ingress  │                │
│  │ kind: Ingress         │  ─────▶  │ with TLS annotation  │                │
│  │ annotations:          │          │ or Certificate CRD   │                │
│  │   cert-manager.io/    │          └──────────┬───────────┘                │
│  │   cluster-issuer:     │                     │                            │
│  │   letsencrypt-prod    │                     ▼                            │
│  └──────────────────────┘          ┌──────────────────────┐                │
│                                    │ 3. Creates Order     │                │
│  6. Certificate Ready              │    & Challenge       │                │
│  ┌──────────────────────┐          └──────────┬───────────┘                │
│  │ Secret created with   │                     │                            │
│  │ tls.crt and tls.key  │                     ▼                            │
│  │ mounted to Ingress   │          ┌──────────────────────┐                │
│  └──────────────────────┘          │ 4. HTTP01 Challenge  │                │
│           ▲                        │ via NGINX Ingress    │                │
│           │                        └──────────┬───────────┘                │
│           │                                   │                            │
│           │                                   ▼                            │
│           │                        ┌──────────────────────┐                │
│           └────────────────────────│ 5. Let's Encrypt     │                │
│                                    │    Issues Certificate│                │
│                                    └──────────────────────┘                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### ClusterIssuers Created

| Issuer Name | Type | Use Case | Trusted |
|-------------|------|----------|---------|
| `self-signed` | Self-Signed | Internal services, development | No |
| `letsencrypt-staging` | ACME (Let's Encrypt) | Testing cert flow before production | No |
| `letsencrypt-prod` | ACME (Let's Encrypt) | Production workloads | Yes |

### HTTP01 Challenge Solver

This module uses the **HTTP01** challenge type with NGINX Ingress:

1. cert-manager creates a temporary Ingress route at `/.well-known/acme-challenge/<token>`
2. Let's Encrypt makes an HTTP request to verify domain ownership
3. Upon verification, certificate is issued and stored as a Kubernetes Secret

---

## Prerequisites

- Kubernetes cluster (AKS)
- NGINX Ingress Controller deployed (or other ingress with `ingress_class` configured)
- Helm and Kubernetes providers configured in root module

---

## Usage

### Basic Usage (in root module)

```hcl
module "cert_manager" {
  source = "./modules/helm-cert-manager-tf"

  letsencrypt_email = "admin@example.com"
  ingress_class     = "nginx"

  depends_on = [module.ingress_nginx]
}
```

### With All Options

```hcl
module "cert_manager" {
  source = "./modules/helm-cert-manager-tf"

  # General
  namespace     = "cert-manager"
  chart_version = "v1.14.3"
  helm_timeout  = 600

  # ClusterIssuers
  create_self_signed_issuer  = true
  create_letsencrypt_issuers = true
  letsencrypt_email          = "admin@example.com"
  ingress_class              = "nginx"

  # Resources
  resources = {
    requests = {
      cpu    = "10m"
      memory = "32Mi"
    }
    limits = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }

  # Monitoring
  enable_prometheus_metrics = true

  depends_on = [module.ingress_nginx]
}
```

---

## Using Certificates in Your Applications

### Option 1: Ingress Annotation (Recommended)

Add annotations to your Ingress to automatically provision certificates:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"  # or letsencrypt-staging
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - myapp.example.com
      secretName: myapp-tls  # cert-manager creates this Secret
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
```

### Option 2: Certificate Resource

Create a Certificate resource explicitly:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: myapp-cert
  namespace: default
spec:
  secretName: myapp-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - myapp.example.com
    - www.myapp.example.com
```

### Option 3: Self-Signed (Internal Services)

For internal services that don't need public trust:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: internal-app
  annotations:
    cert-manager.io/cluster-issuer: "self-signed"
spec:
  tls:
    - hosts:
        - internal.cluster.local
      secretName: internal-tls
  # ... rest of config
```

---

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `namespace` | `string` | `"cert-manager"` | Kubernetes namespace for cert-manager |
| `chart_version` | `string` | `"v1.14.3"` | Cert-manager Helm chart version |
| `helm_timeout` | `number` | `600` | Helm release timeout in seconds |
| `create_self_signed_issuer` | `bool` | `true` | Create a self-signed ClusterIssuer |
| `create_letsencrypt_issuers` | `bool` | `true` | Create Let's Encrypt ClusterIssuers |
| `letsencrypt_email` | `string` | `""` | Email for Let's Encrypt notifications |
| `ingress_class` | `string` | `"nginx"` | Ingress class for HTTP01 solver |
| `enable_prometheus_metrics` | `bool` | `true` | Enable Prometheus metrics endpoint |
| `resources` | `object` | See below | Resource requests/limits |

### Default Resources

```hcl
resources = {
  requests = {
    cpu    = "10m"
    memory = "32Mi"
  }
  limits = {
    cpu    = "100m"
    memory = "128Mi"
  }
}
```

---

## Outputs

| Name | Description |
|------|-------------|
| `namespace` | Namespace where cert-manager is installed |
| `helm_release_name` | Name of the Helm release |
| `helm_release_version` | Version of the deployed chart |
| `helm_release_status` | Status of the Helm release |
| `self_signed_issuer_name` | Name of self-signed ClusterIssuer (if created) |
| `letsencrypt_staging_issuer_name` | Name of Let's Encrypt staging ClusterIssuer |
| `letsencrypt_prod_issuer_name` | Name of Let's Encrypt prod ClusterIssuer |

---

## Troubleshooting

### Check cert-manager pods

```bash
kubectl get pods -n cert-manager
```

### Check ClusterIssuers

```bash
kubectl get clusterissuers
kubectl describe clusterissuer letsencrypt-prod
```

### Check Certificate status

```bash
kubectl get certificates -A
kubectl describe certificate <name> -n <namespace>
```

### Check Certificate requests

```bash
kubectl get certificaterequests -A
```

### Check Orders and Challenges

```bash
kubectl get orders -A
kubectl get challenges -A
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Certificate stuck in `Pending` | HTTP01 challenge failing | Check Ingress is accessible, DNS resolves |
| `ACME server rejected` | Rate limiting or invalid domain | Use staging issuer first, verify domain ownership |
| `no configured issuers` | Issuer not found | Check issuer name matches annotation exactly |
| Challenge timeout | Ingress not routing correctly | Verify NGINX Ingress is working |

### View cert-manager logs

```bash
kubectl logs -n cert-manager -l app=cert-manager --tail=100
```

---

## Best Practices

1. **Test with staging first**: Always use `letsencrypt-staging` before `letsencrypt-prod` to avoid rate limits
2. **Set email**: Provide a valid email for certificate expiry notifications
3. **Use wildcard sparingly**: Wildcard certs require DNS01 challenge (not configured by default)
4. **Monitor expiry**: Set up alerts for certificate expiration
5. **Resource limits**: Adjust resources based on certificate volume

---

## Rate Limits (Let's Encrypt)

| Limit | Value |
|-------|-------|
| Certificates per domain | 50 per week |
| Duplicate certificates | 5 per week |
| Failed validations | 5 per hour |
| Orders per account | 300 per 3 hours |

Use `letsencrypt-staging` for testing - it has much higher limits but certificates are not trusted.

---

## Components Deployed

| Component | Description |
|-----------|-------------|
| **cert-manager controller** | Watches for Certificate resources, manages issuance |
| **webhook** | Validates and mutates cert-manager resources |
| **cainjector** | Injects CA bundles into webhooks and API servers |
| **CRDs** | Certificate, Issuer, ClusterIssuer, Order, Challenge |

---

## License

MIT
