terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

resource "azurerm_mssql_server" "this" {
  name                                         = var.name
  resource_group_name                          = var.resource_group_name
  location                                     = var.location
  version                                      = var.version
  administrator_login                          = var.administrator_login
  administrator_login_password                 = var.administrator_login_password
  minimum_tls_version                          = var.minimum_tls_version
  public_network_access_enabled                = var.public_network_access_enabled
  outbound_network_restriction_enabled         = var.outbound_network_restriction_enabled
  primary_user_assigned_identity_id            = var.primary_user_assigned_identity_id
  transparent_data_encryption_key_vault_key_id = var.transparent_data_encryption_key_vault_key_id

  dynamic "azuread_administrator" {
    for_each = var.azuread_administrator != null ? [var.azuread_administrator] : []
    content {
      login_username              = azuread_administrator.value.login_username
      object_id                   = azuread_administrator.value.object_id
      tenant_id                   = azuread_administrator.value.tenant_id
      azuread_authentication_only = azuread_administrator.value.azuread_authentication_only
    }
  }

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  tags = var.tags
}

resource "azurerm_mssql_firewall_rule" "this" {
  for_each = var.firewall_rules

  name             = each.key
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = each.value.start_ip
  end_ip_address   = each.value.end_ip
}

resource "azurerm_mssql_virtual_network_rule" "this" {
  for_each = var.vnet_rules

  name      = each.key
  server_id = azurerm_mssql_server.this.id
  subnet_id = each.value.subnet_id
}
