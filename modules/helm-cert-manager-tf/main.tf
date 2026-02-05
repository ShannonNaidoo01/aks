# -----------------------------------------------------------------------------
# Cert-Manager Helm Deployment
# -----------------------------------------------------------------------------
# This module deploys cert-manager and configures ClusterIssuers for
# automated TLS certificate management.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Namespace
# -----------------------------------------------------------------------------
resource "kubernetes_namespace_v1" "cert_manager" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/name"       = "cert-manager"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# Cert-Manager Helm Release
# -----------------------------------------------------------------------------
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.cert_manager.metadata[0].name

  # Install CRDs - required for cert-manager to function
  set {
    name  = "installCRDs"
    value = "true"
  }

  # Resource requests/limits
  set {
    name  = "resources.requests.cpu"
    value = var.resources.requests.cpu
  }

  set {
    name  = "resources.requests.memory"
    value = var.resources.requests.memory
  }

  set {
    name  = "resources.limits.cpu"
    value = var.resources.limits.cpu
  }

  set {
    name  = "resources.limits.memory"
    value = var.resources.limits.memory
  }

  # Webhook resource configuration
  set {
    name  = "webhook.resources.requests.cpu"
    value = "10m"
  }

  set {
    name  = "webhook.resources.requests.memory"
    value = "32Mi"
  }

  # CA Injector resource configuration
  set {
    name  = "cainjector.resources.requests.cpu"
    value = "10m"
  }

  set {
    name  = "cainjector.resources.requests.memory"
    value = "32Mi"
  }

  # Enable Prometheus metrics
  set {
    name  = "prometheus.enabled"
    value = var.enable_prometheus_metrics
  }

  # Pod labels
  set {
    name  = "podLabels.app\\.kubernetes\\.io/part-of"
    value = "cert-manager"
  }

  dynamic "set" {
    for_each = var.extra_values
    content {
      name  = set.key
      value = set.value
    }
  }

  timeout = var.helm_timeout

  depends_on = [kubernetes_namespace_v1.cert_manager]
}

# -----------------------------------------------------------------------------
# Self-Signed ClusterIssuer (for internal certificates)
# -----------------------------------------------------------------------------
resource "kubernetes_manifest" "self_signed_issuer" {
  count = var.create_self_signed_issuer ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "self-signed"
    }
    spec = {
      selfSigned = {}
    }
  }

  depends_on = [helm_release.cert_manager]
}

# -----------------------------------------------------------------------------
# Let's Encrypt Staging ClusterIssuer
# -----------------------------------------------------------------------------
resource "kubernetes_manifest" "letsencrypt_staging_issuer" {
  count = var.create_letsencrypt_issuers && var.letsencrypt_email != "" ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-staging"
    }
    spec = {
      acme = {
        email  = var.letsencrypt_email
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-staging-account-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = var.ingress_class
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}

# -----------------------------------------------------------------------------
# Let's Encrypt Production ClusterIssuer
# -----------------------------------------------------------------------------
resource "kubernetes_manifest" "letsencrypt_prod_issuer" {
  count = var.create_letsencrypt_issuers && var.letsencrypt_email != "" ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        email  = var.letsencrypt_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-prod-account-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = var.ingress_class
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}
