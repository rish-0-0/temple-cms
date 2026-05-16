resource "azurerm_key_vault" "this" {
  name                       = var.name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
}

resource "azurerm_role_assignment" "terraform_admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.terraform_principal_id
}

resource "azurerm_key_vault_secret" "this" {
  for_each     = nonsensitive(toset(keys(var.secrets)))
  name         = each.value
  value        = var.secrets[each.value]
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_role_assignment.terraform_admin]
}
