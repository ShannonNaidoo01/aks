# -----------------------------------------------------------------------------
# Cert-Manager Outputs
# -----------------------------------------------------------------------------

output "namespace" {
  description = "The namespace where cert-manager is installed"
  value       = kubernetes_namespace.cert_manager.metadata[0].name
}

output "helm_release_name" {
  description = "The name of the Helm release"
  value       = helm_release.cert_manager.name
}

output "helm_release_version" {
  description = "The version of the deployed chart"
  value       = helm_release.cert_manager.version
}

output "helm_release_status" {
  description = "The status of the Helm release"
  value       = helm_release.cert_manager.status
}

# -----------------------------------------------------------------------------
# ClusterIssuer Names
# -----------------------------------------------------------------------------

output "self_signed_issuer_name" {
  description = "Name of the self-signed ClusterIssuer (if created)"
  value       = var.create_self_signed_issuer ? "self-signed" : null
}

output "letsencrypt_staging_issuer_name" {
  description = "Name of the Let's Encrypt staging ClusterIssuer (if created)"
  value       = var.create_letsencrypt_issuers && var.letsencrypt_email != "" ? "letsencrypt-staging" : null
}

output "letsencrypt_prod_issuer_name" {
  description = "Name of the Let's Encrypt production ClusterIssuer (if created)"
  value       = var.create_letsencrypt_issuers && var.letsencrypt_email != "" ? "letsencrypt-prod" : null
}
