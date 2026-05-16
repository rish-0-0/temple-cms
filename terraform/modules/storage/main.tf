resource "azurerm_storage_account" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  account_kind                  = "StorageV2"
  access_tier                   = "Hot"
  public_network_access_enabled = true
  min_tls_version               = "TLS1_2"
}

resource "azurerm_storage_container" "media" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "blob"
}
