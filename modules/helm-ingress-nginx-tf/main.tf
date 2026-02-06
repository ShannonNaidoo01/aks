# -----------------------------------------------------------------------------
# NGINX Ingress Controller for AKS
# Deploys NGINX Ingress Controller via Helm with Azure Load Balancer integration
# -----------------------------------------------------------------------------

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.25.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Namespace for Ingress Controller
# -----------------------------------------------------------------------------

resource "kubernetes_namespace_v1" "ingress_nginx" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/name"       = "ingress-nginx"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# Build the set values list for Helm
# -----------------------------------------------------------------------------

locals {
  # Base set values
  base_set_values = [
    {
      name  = "controller.replicaCount"
      value = tostring(var.replica_count)
    },
    {
      name  = "controller.nodeSelector.kubernetes\\.io/os"
      value = "linux"
    },
    {
      name  = "controller.service.type"
      value = "LoadBalancer"
    },
    {
      name  = "controller.service.externalTrafficPolicy"
      value = var.external_traffic_policy
    },
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path"
      value = "/healthz"
    },
    {
      name  = "controller.resources.requests.cpu"
      value = var.resources.requests.cpu
    },
    {
      name  = "controller.resources.requests.memory"
      value = var.resources.requests.memory
    },
    {
      name  = "controller.resources.limits.cpu"
      value = var.resources.limits.cpu
    },
    {
      name  = "controller.resources.limits.memory"
      value = var.resources.limits.memory
    },
    {
      name  = "controller.metrics.enabled"
      value = tostring(var.metrics_enabled)
    },
    {
      name  = "controller.metrics.serviceMonitor.enabled"
      value = tostring(var.service_monitor_enabled)
    },
    {
      name  = "controller.minAvailable"
      value = tostring(var.min_available)
    },
    {
      name  = "controller.ingressClassResource.name"
      value = var.ingress_class_name
    },
    {
      name  = "controller.ingressClassResource.default"
      value = tostring(var.default_ingress_class)
    },
    {
      name  = "controller.admissionWebhooks.enabled"
      value = tostring(var.admission_webhooks_enabled)
    },
  ]

  # Conditional set values
  load_balancer_ip_set = var.load_balancer_ip != "" ? [
    {
      name  = "controller.service.loadBalancerIP"
      value = var.load_balancer_ip
    }
  ] : []

  internal_lb_set = var.internal_load_balancer ? [
    {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal"
      value = "true"
    }
  ] : []

  # Default SSL certificate configuration
  default_ssl_cert_set = var.default_ssl_certificate_secret != "" ? [
    {
      name  = "controller.extraArgs.default-ssl-certificate"
      value = "${var.namespace}/${var.default_ssl_certificate_secret}"
    }
  ] : []

  # Combine all set values
  all_set_values = concat(
    local.base_set_values,
    local.load_balancer_ip_set,
    local.internal_lb_set,
    local.default_ssl_cert_set,
    var.additional_set_values
  )
}

# -----------------------------------------------------------------------------
# NGINX Ingress Controller Helm Release
# -----------------------------------------------------------------------------

resource "helm_release" "ingress_nginx" {
  name       = var.release_name
  namespace  = kubernetes_namespace_v1.ingress_nginx.metadata[0].name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.chart_version

  # Wait for the release to be deployed
  wait    = true
  timeout = var.helm_timeout

  # Helm provider v3.0.0+ uses set as a list argument
  set = local.all_set_values

  # Custom values file (if provided)
  values = var.values_file != "" ? [file(var.values_file)] : []
}

# -----------------------------------------------------------------------------
# Wait for LoadBalancer IP assignment
# -----------------------------------------------------------------------------

data "kubernetes_service_v1" "ingress_nginx" {
  metadata {
    name      = "${var.release_name}-ingress-nginx-controller"
    namespace = kubernetes_namespace_v1.ingress_nginx.metadata[0].name
  }

  depends_on = [helm_release.ingress_nginx]
}
