# -----------------------------------------------------------------------------
# Cert-Manager Helm Deployment
# -----------------------------------------------------------------------------
# This module deploys cert-manager and configures ClusterIssuers for
# automated TLS certificate management.
# -----------------------------------------------------------------------------

# Provider sources must be declared in modules for non-hashicorp providers
# This is a Terraform/OpenTofu requirement - configurations come from root
terraform {
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
  }
}

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

locals {
  # Workload identity configuration for Azure DNS access
  workload_identity_enabled = var.enable_dns01_solver && var.cert_manager_client_id != ""
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.cert_manager.metadata[0].name

  values = [yamlencode({
    installCRDs = true

    # Service account configuration for workload identity
    serviceAccount = {
      name = var.cert_manager_service_account
      labels = local.workload_identity_enabled ? {
        "azure.workload.identity/use" = "true"
      } : {}
      annotations = local.workload_identity_enabled ? {
        "azure.workload.identity/client-id" = var.cert_manager_client_id
      } : {}
    }

    # Pod labels for workload identity
    podLabels = merge(
      { "app.kubernetes.io/part-of" = "cert-manager" },
      local.workload_identity_enabled ? { "azure.workload.identity/use" = "true" } : {}
    )

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
  })]

  timeout = var.helm_timeout

  depends_on = [kubernetes_namespace_v1.cert_manager]
}

# -----------------------------------------------------------------------------
# Wait for cert-manager to be ready before creating issuers
# -----------------------------------------------------------------------------
resource "time_sleep" "wait_for_cert_manager" {
  depends_on      = [helm_release.cert_manager]
  create_duration = "30s"
}

# -----------------------------------------------------------------------------
# Self-Signed ClusterIssuer (for internal certificates)
# -----------------------------------------------------------------------------
resource "kubectl_manifest" "self_signed_issuer" {
  count = var.create_self_signed_issuer ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: self-signed
    spec:
      selfSigned: {}
  YAML

  depends_on = [time_sleep.wait_for_cert_manager]
}

# -----------------------------------------------------------------------------
# Let's Encrypt Staging ClusterIssuer
# -----------------------------------------------------------------------------
resource "kubectl_manifest" "letsencrypt_staging_issuer" {
  count = var.create_letsencrypt_issuers && var.letsencrypt_email != "" ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-staging
    spec:
      acme:
        email: ${var.letsencrypt_email}
        server: https://acme-staging-v02.api.letsencrypt.org/directory
        privateKeySecretRef:
          name: letsencrypt-staging-account-key
        solvers:
        - http01:
            ingress:
              class: ${var.ingress_class}
  YAML

  depends_on = [time_sleep.wait_for_cert_manager]
}

# -----------------------------------------------------------------------------
# Let's Encrypt Production ClusterIssuer
# -----------------------------------------------------------------------------
resource "kubectl_manifest" "letsencrypt_prod_issuer" {
  count = var.create_letsencrypt_issuers && var.letsencrypt_email != "" ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-prod
    spec:
      acme:
        email: ${var.letsencrypt_email}
        server: https://acme-v02.api.letsencrypt.org/directory
        privateKeySecretRef:
          name: letsencrypt-prod-account-key
        solvers:
        - http01:
            ingress:
              class: ${var.ingress_class}
  YAML

  depends_on = [time_sleep.wait_for_cert_manager]
}

# -----------------------------------------------------------------------------
# Let's Encrypt DNS-01 Staging ClusterIssuer (for wildcard certificates)
# -----------------------------------------------------------------------------
resource "kubectl_manifest" "letsencrypt_dns_staging_issuer" {
  count = var.enable_dns01_solver && var.letsencrypt_email != "" ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-dns-staging
    spec:
      acme:
        email: ${var.letsencrypt_email}
        server: https://acme-staging-v02.api.letsencrypt.org/directory
        privateKeySecretRef:
          name: letsencrypt-dns-staging-account-key
        solvers:
        - dns01:
            azureDNS:
              subscriptionID: ${var.azure_subscription_id}
              resourceGroupName: ${var.azure_dns_zone_resource_group}
              hostedZoneName: ${var.azure_dns_zone_name}
              environment: AzurePublicCloud
              managedIdentity:
                clientID: ${var.cert_manager_client_id}
  YAML

  depends_on = [time_sleep.wait_for_cert_manager]
}

# -----------------------------------------------------------------------------
# Let's Encrypt DNS-01 Production ClusterIssuer (for wildcard certificates)
# -----------------------------------------------------------------------------
resource "kubectl_manifest" "letsencrypt_dns_prod_issuer" {
  count = var.enable_dns01_solver && var.letsencrypt_email != "" ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-dns-prod
    spec:
      acme:
        email: ${var.letsencrypt_email}
        server: https://acme-v02.api.letsencrypt.org/directory
        privateKeySecretRef:
          name: letsencrypt-dns-prod-account-key
        solvers:
        - dns01:
            azureDNS:
              subscriptionID: ${var.azure_subscription_id}
              resourceGroupName: ${var.azure_dns_zone_resource_group}
              hostedZoneName: ${var.azure_dns_zone_name}
              environment: AzurePublicCloud
              managedIdentity:
                clientID: ${var.cert_manager_client_id}
  YAML

  depends_on = [time_sleep.wait_for_cert_manager]
}

# -----------------------------------------------------------------------------
# Wildcard Certificates
# -----------------------------------------------------------------------------
resource "kubectl_manifest" "wildcard_certificate" {
  for_each = var.wildcard_certificates

  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: ${each.key}
      namespace: ${each.value.target_namespace}
    spec:
      secretName: ${each.value.secret_name}
      issuerRef:
        name: ${each.value.issuer_name}
        kind: ClusterIssuer
      dnsNames:
      - "${each.value.dns_name}"
      # Also include the apex domain for flexibility
      - "${trimprefix(each.value.dns_name, "*.")}"
  YAML

  depends_on = [
    kubectl_manifest.letsencrypt_dns_staging_issuer,
    kubectl_manifest.letsencrypt_dns_prod_issuer
  ]
}
