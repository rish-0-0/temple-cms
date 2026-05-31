variable "project" {
  type    = string
  default = "divyakatha"
}

variable "location" {
  type    = string
  default = "southeastasia"
}

variable "custom_hostname" {
  description = "Public hostname for the CMS. DNS CNAME must point this at the App Service default hostname before apply."
  type        = string
  default     = "cms.sibani-panigrahy.com"
}

variable "image" {
  description = "Full container image reference, e.g. ghcr.io/owner/temple-cms:latest"
  type        = string
}

variable "ghcr_username" {
  description = "GitHub username that owns the GHCR package"
  type        = string
}

variable "ghcr_token" {
  description = "GitHub PAT with read:packages scope, for App Service to pull from GHCR"
  type        = string
  sensitive   = true
}

# Strapi secrets — supplied via TF_VAR_* from GitHub Actions Secrets.
# Terraform writes these into Key Vault; App Service reads them by reference.
variable "strapi_app_keys" {
  type      = string
  sensitive = true
}

variable "strapi_api_token_salt" {
  type      = string
  sensitive = true
}

variable "strapi_admin_jwt_secret" {
  type      = string
  sensitive = true
}

variable "strapi_transfer_token_salt" {
  type      = string
  sensitive = true
}

variable "strapi_jwt_secret" {
  type      = string
  sensitive = true
}

variable "strapi_encryption_key" {
  type      = string
  sensitive = true
}

variable "entra_tenant_id" {
  type      = string
  sensitive = true
}

variable "entra_client_id" {
  type      = string
  sensitive = true
}

variable "entra_client_secret" {
  type      = string
  sensitive = true
}
