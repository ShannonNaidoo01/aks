# -----------------------------------------------------------------------------
# Kubernetes Cluster Test Module
# -----------------------------------------------------------------------------
# Deploys a simple nginx pod with ingress to verify cluster functionality
# -----------------------------------------------------------------------------

terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

locals {
  app_name = "cluster-test"
  labels = {
    "app.kubernetes.io/name"       = local.app_name
    "app.kubernetes.io/component"  = "test"
    "app.kubernetes.io/managed-by" = "terraform"
    "environment"                  = var.environment
  }
}

# -----------------------------------------------------------------------------
# Namespace
# -----------------------------------------------------------------------------
resource "kubernetes_namespace_v1" "cluster_test" {
  metadata {
    name   = local.app_name
    labels = local.labels
  }
}

# -----------------------------------------------------------------------------
# Deployment
# -----------------------------------------------------------------------------
resource "kubernetes_deployment_v1" "cluster_test" {
  metadata {
    name      = local.app_name
    namespace = kubernetes_namespace_v1.cluster_test.metadata[0].name
    labels    = local.labels
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = local.app_name
      }
    }

    template {
      metadata {
        labels = local.labels
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:alpine"

          port {
            container_port = 80
          }

          resources {
            requests = {
              cpu    = "10m"
              memory = "16Mi"
            }
            limits = {
              cpu    = "50m"
              memory = "32Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Service
# -----------------------------------------------------------------------------
resource "kubernetes_service_v1" "cluster_test" {
  metadata {
    name      = local.app_name
    namespace = kubernetes_namespace_v1.cluster_test.metadata[0].name
    labels    = local.labels
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = local.app_name
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

# -----------------------------------------------------------------------------
# Ingress
# -----------------------------------------------------------------------------
resource "kubernetes_ingress_v1" "cluster_test" {
  count = var.hostname != "" ? 1 : 0

  metadata {
    name      = local.app_name
    namespace = kubernetes_namespace_v1.cluster_test.metadata[0].name
    labels    = local.labels

    annotations = {
      "kubernetes.io/ingress.class"    = "nginx"
      "cert-manager.io/cluster-issuer" = var.cluster_issuer
    }
  }

  spec {
    tls {
      hosts       = [var.hostname]
      secret_name = "${local.app_name}-tls"
    }

    rule {
      host = var.hostname

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service_v1.cluster_test.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
