# -----------------------------------------------------------------------------
# Ingress Controller Outputs
# -----------------------------------------------------------------------------

output "namespace" {
  description = "The namespace where the ingress controller is deployed"
  value       = kubernetes_namespace_v1.ingress_nginx.metadata[0].name
}

output "release_name" {
  description = "The Helm release name"
  value       = helm_release.ingress_nginx.name
}

output "chart_version" {
  description = "The deployed Helm chart version"
  value       = helm_release.ingress_nginx.version
}

output "ingress_class_name" {
  description = "The IngressClass name to use in Ingress resources"
  value       = var.ingress_class_name
}

# -----------------------------------------------------------------------------
# Load Balancer Outputs
# -----------------------------------------------------------------------------

output "load_balancer_ip" {
  description = "The external IP address of the ingress controller LoadBalancer"
  value       = try(data.kubernetes_service_v1.ingress_nginx.status[0].load_balancer[0].ingress[0].ip, "pending")
}

output "load_balancer_hostname" {
  description = "The external hostname of the ingress controller LoadBalancer (if applicable)"
  value       = try(data.kubernetes_service_v1.ingress_nginx.status[0].load_balancer[0].ingress[0].hostname, "")
}

# -----------------------------------------------------------------------------
# Service Details
# -----------------------------------------------------------------------------

output "controller_service_name" {
  description = "The name of the controller service"
  value       = "${var.release_name}-ingress-nginx-controller"
}

output "controller_service_namespace" {
  description = "The namespace of the controller service"
  value       = kubernetes_namespace_v1.ingress_nginx.metadata[0].name
}
