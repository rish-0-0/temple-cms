output "webapp_url" {
  value = "https://${module.webapp.default_hostname}"
}

output "custom_domain_url" {
  value = var.custom_hostname == "" ? null : "https://${var.custom_hostname}"
}

output "dns_cname_target" {
  description = "Set a CNAME at GoDaddy: <subdomain> -> this value"
  value       = module.webapp.default_hostname
}

output "postgres_fqdn" {
  value = module.database.fqdn
}

output "media_blob_endpoint" {
  value = module.storage.primary_blob_endpoint
}

output "key_vault_name" {
  value = module.keyvault.name
}
