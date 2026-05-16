data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
  numeric = true
}

resource "random_password" "postgres_admin" {
  length           = 32
  special          = true
  override_special = "_-"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

locals {
  suffix = random_string.suffix.result
  rg     = "rg-${var.project}"
}

resource "azurerm_resource_group" "main" {
  name     = local.rg
  location = var.location
}

module "storage" {
  source              = "./modules/storage"
  name                = "${var.project}media${local.suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

module "database" {
  source                 = "./modules/database"
  name                   = "psql-${var.project}-${local.suffix}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  administrator_password = random_password.postgres_admin.result
}

module "keyvault" {
  source                 = "./modules/keyvault"
  name                   = "kv-${var.project}-${local.suffix}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  tenant_id              = data.azurerm_client_config.current.tenant_id
  terraform_principal_id = data.azurerm_client_config.current.object_id
  secrets = {
    "APP-KEYS"            = var.strapi_app_keys
    "API-TOKEN-SALT"      = var.strapi_api_token_salt
    "ADMIN-JWT-SECRET"    = var.strapi_admin_jwt_secret
    "TRANSFER-TOKEN-SALT" = var.strapi_transfer_token_salt
    "JWT-SECRET"          = var.strapi_jwt_secret
    "ENCRYPTION-KEY"      = var.strapi_encryption_key
    "POSTGRES-PASSWORD"   = random_password.postgres_admin.result
    "GHCR-TOKEN"          = var.ghcr_token
    "STORAGE-ACCOUNT-KEY" = module.storage.primary_access_key
  }
}

module "webapp" {
  source              = "./modules/webapp"
  name                = "${var.project}-cms"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  image               = var.image
  ghcr_username       = var.ghcr_username
  ghcr_token          = var.ghcr_token
  key_vault_id        = module.keyvault.id
  custom_hostname     = var.custom_hostname

  app_settings = {
    HOST          = "0.0.0.0"
    PORT          = "1337"
    NODE_ENV      = "production"
    WEBSITES_PORT = "1337"

    DATABASE_CLIENT                  = "postgres"
    DATABASE_HOST                    = module.database.fqdn
    DATABASE_PORT                    = "5432"
    DATABASE_NAME                    = module.database.database_name
    DATABASE_USERNAME                = module.database.administrator_login
    DATABASE_SSL                     = "true"
    DATABASE_SSL_REJECT_UNAUTHORIZED = "false"
    DATABASE_PASSWORD                = "@Microsoft.KeyVault(SecretUri=${module.keyvault.secret_uris["POSTGRES-PASSWORD"]})"

    APP_KEYS            = "@Microsoft.KeyVault(SecretUri=${module.keyvault.secret_uris["APP-KEYS"]})"
    API_TOKEN_SALT      = "@Microsoft.KeyVault(SecretUri=${module.keyvault.secret_uris["API-TOKEN-SALT"]})"
    ADMIN_JWT_SECRET    = "@Microsoft.KeyVault(SecretUri=${module.keyvault.secret_uris["ADMIN-JWT-SECRET"]})"
    TRANSFER_TOKEN_SALT = "@Microsoft.KeyVault(SecretUri=${module.keyvault.secret_uris["TRANSFER-TOKEN-SALT"]})"
    JWT_SECRET          = "@Microsoft.KeyVault(SecretUri=${module.keyvault.secret_uris["JWT-SECRET"]})"
    ENCRYPTION_KEY      = "@Microsoft.KeyVault(SecretUri=${module.keyvault.secret_uris["ENCRYPTION-KEY"]})"

    STORAGE_ACCOUNT        = module.storage.account_name
    STORAGE_CONTAINER_NAME = module.storage.container_name
    STORAGE_URL            = module.storage.primary_blob_endpoint
    STORAGE_ACCOUNT_KEY    = "@Microsoft.KeyVault(SecretUri=${module.keyvault.secret_uris["STORAGE-ACCOUNT-KEY"]})"
  }
}

# Postgres firewall — allow Azure-internal IPs only.
# The 0.0.0.0/0.0.0.0 rule is Azure-specific magic meaning "any Azure-internal IP."
# This is broader than ideal (other Azure tenants can reach the listener), but those
# attempts still need the 32-char random Postgres password to authenticate.
#
# The "tighter" alternative — whitelisting the App Service's possible_outbound_ip_addresses —
# was rejected because that field is only known after apply, which makes for_each unplannable.
# Revisit if you ever move to VNet integration (would require Standard App Service tier, +$60/mo).
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "allow-azure-services"
  server_id        = module.database.server_id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
