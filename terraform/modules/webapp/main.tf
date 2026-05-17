resource "azurerm_service_plan" "this" {
  name                = "asp-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name
}

resource "azurerm_linux_web_app" "this" {
  name                = "app-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                               = true
    ftps_state                              = "Disabled"
    minimum_tls_version                     = "1.2"
    container_registry_use_managed_identity = false

    application_stack {
      docker_image_name        = join("/", slice(split("/", var.image), 1, length(split("/", var.image))))
      docker_registry_url      = "https://ghcr.io"
      docker_registry_username = var.ghcr_username
      docker_registry_password = var.ghcr_token
    }
  }

  app_settings = var.app_settings

  logs {
    application_logs {
      file_system_level = "Verbose"
    }
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
    detailed_error_messages = true
    failed_request_tracing  = true
  }
}

# Allow the Web App's managed identity to read Key Vault secrets.
resource "azurerm_role_assignment" "kv_reader" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.this.identity[0].principal_id
}

# -------------------------------------------------------------------
# Custom domain (only when var.custom_hostname is non-empty)
# DNS prerequisite: CNAME <subdomain> -> <azurerm_linux_web_app.this.default_hostname>
# -------------------------------------------------------------------
resource "azurerm_app_service_custom_hostname_binding" "this" {
  count               = var.custom_hostname == "" ? 0 : 1
  hostname            = var.custom_hostname
  app_service_name    = azurerm_linux_web_app.this.name
  resource_group_name = var.resource_group_name

  lifecycle {
    ignore_changes = [ssl_state, thumbprint]
  }
}

resource "azurerm_app_service_managed_certificate" "this" {
  count                      = var.custom_hostname == "" ? 0 : 1
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.this[0].id
}

resource "azurerm_app_service_certificate_binding" "this" {
  count               = var.custom_hostname == "" ? 0 : 1
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.this[0].id
  certificate_id      = azurerm_app_service_managed_certificate.this[0].id
  ssl_state           = "SniEnabled"
}
