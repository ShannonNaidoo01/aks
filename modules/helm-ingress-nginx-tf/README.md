# NGINX Ingress Controller Module

Deploys NGINX Ingress Controller to AKS using Helm with Azure Load Balancer integration.

## Features

- NGINX Ingress Controller via official Helm chart
- Azure Load Balancer integration (public or internal)
- Prometheus metrics support
- Pod Disruption Budget for high availability
- Admission webhooks for ingress validation

## Usage

```hcl
module "ingress_nginx" {
  source = "./modules/helm-ingress-nginx-tf"

  # Optional: customize settings
  replica_count          = 2
  internal_load_balancer = false
  metrics_enabled        = true
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `namespace` | Kubernetes namespace | `string` | `"ingress-nginx"` |
| `chart_version` | Helm chart version | `string` | `"4.9.1"` |
| `replica_count` | Number of controller replicas | `number` | `2` |
| `internal_load_balancer` | Use internal (private) LB | `bool` | `false` |
| `ingress_class_name` | IngressClass name | `string` | `"nginx"` |
| `metrics_enabled` | Enable Prometheus metrics | `bool` | `true` |

## Outputs

| Name | Description |
|------|-------------|
| `load_balancer_ip` | External IP of the ingress controller |
| `ingress_class_name` | IngressClass to use in Ingress resources |
| `namespace` | Namespace where controller is deployed |

## Example Ingress Resource

After deploying, create Ingress resources:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app-service
                port:
                  number: 80
```

## Architecture Notes

This module deploys a public-facing ingress controller. For production with Azure Front Door:

1. Set `internal_load_balancer = true`
2. Configure Azure Front Door to route to the internal LB
3. See `docs/architecture/TECH_STACK.md` for network zone details
