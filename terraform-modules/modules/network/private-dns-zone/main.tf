terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

resource "azurerm_private_dns_zone" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Virtual Network Links
resource "azurerm_private_dns_zone_virtual_network_link" "links" {
  for_each = var.virtual_network_links

  name                  = each.key
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = each.value.virtual_network_id
  registration_enabled  = each.value.registration_enabled

  tags = var.tags
}
