# -----------------------------------------------------------------------------
# Cluster Test Outputs
# -----------------------------------------------------------------------------

output "namespace" {
  description = "Namespace where cluster-test is deployed"
  value       = kubernetes_namespace_v1.cluster_test.metadata[0].name
}

output "service_name" {
  description = "Service name"
  value       = kubernetes_service_v1.cluster_test.metadata[0].name
}

output "hostname" {
  description = "Hostname for accessing the test app"
  value       = var.hostname
}

output "url" {
  description = "Full URL for the test app"
  value       = var.hostname != "" ? "https://${var.hostname}" : ""
}
