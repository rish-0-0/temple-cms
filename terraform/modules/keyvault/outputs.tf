output "id" {
  value = azurerm_key_vault.this.id
}

output "name" {
  value = azurerm_key_vault.this.name
}

output "secret_uris" {
  description = "Map of secret name -> versionless KV URI, for use in App Service Key Vault references."
  value       = { for k, s in azurerm_key_vault_secret.this : k => s.versionless_id }
}
