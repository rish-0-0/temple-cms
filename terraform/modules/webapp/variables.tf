variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "sku_name" {
  type    = string
  default = "B1"
}

variable "image" {
  type = string
}

variable "ghcr_username" {
  type = string
}

variable "ghcr_token" {
  type      = string
  sensitive = true
}

variable "key_vault_id" {
  type = string
}

variable "custom_hostname" {
  type    = string
  default = ""
}

variable "app_settings" {
  description = "Strapi app settings. Use the @Microsoft.KeyVault(...) syntax for KV references."
  type        = map(string)
}
