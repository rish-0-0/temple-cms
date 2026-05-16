output "default_hostname" {
  value = azurerm_linux_web_app.this.default_hostname
}

output "possible_outbound_ip_addresses" {
  description = "Comma-separated list of all possible outbound IPv4 addresses for this plan."
  value       = azurerm_linux_web_app.this.possible_outbound_ip_addresses
}

output "principal_id" {
  value = azurerm_linux_web_app.this.identity[0].principal_id
}
