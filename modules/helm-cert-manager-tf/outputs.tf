# -----------------------------------------------------------------------------
# Cert-Manager Outputs
# -----------------------------------------------------------------------------

output "namespace" {
  description = "The namespace where cert-manager is installed"
  value       = kubernetes_namespace_v1.cert_manager.metadata[0].name
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

# -----------------------------------------------------------------------------
# DNS-01 ClusterIssuer Names (for wildcard certificates)
# -----------------------------------------------------------------------------

output "letsencrypt_dns_staging_issuer_name" {
  description = "Name of the Let's Encrypt DNS-01 staging ClusterIssuer (if created)"
  value       = var.enable_dns01_solver && var.letsencrypt_email != "" ? "letsencrypt-dns-staging" : null
}

output "letsencrypt_dns_prod_issuer_name" {
  description = "Name of the Let's Encrypt DNS-01 production ClusterIssuer (if created)"
  value       = var.enable_dns01_solver && var.letsencrypt_email != "" ? "letsencrypt-dns-prod" : null
}

# -----------------------------------------------------------------------------
# Wildcard Certificate Outputs
# -----------------------------------------------------------------------------

output "wildcard_certificates" {
  description = "Map of wildcard certificate details"
  value = {
    for k, v in var.wildcard_certificates : k => {
      secret_name      = v.secret_name
      dns_name         = v.dns_name
      target_namespace = v.target_namespace
    }
  }
}
