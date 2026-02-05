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
  values = [yamlencode({
    installCRDs = true

    resources = {
      requests = {
        cpu    = var.resources.requests.cpu
        memory = var.resources.requests.memory
      }
      limits = {
        cpu    = var.resources.limits.cpu
        memory = var.resources.limits.memory
      }
    }

    webhook = {
      resources = {
        requests = {
          cpu    = "10m"
          memory = "32Mi"
        }
      }
    }

    cainjector = {
      resources = {
        requests = {
          cpu    = "10m"
          memory = "32Mi"
        }
      }
    }

    prometheus = {
      enabled = var.enable_prometheus_metrics
    }

    podLabels = {
      "app.kubernetes.io/part-of" = "cert-manager"
    }
  })]

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
