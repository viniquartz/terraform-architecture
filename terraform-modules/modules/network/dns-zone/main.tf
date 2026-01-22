terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

resource "azurerm_dns_zone" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Optional: DNS records
resource "azurerm_dns_a_record" "records" {
  for_each = var.a_records

  name                = each.key
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  records             = each.value.records
  tags                = var.tags
}

resource "azurerm_dns_cname_record" "records" {
  for_each = var.cname_records

  name                = each.key
  zone_name           = azurerm_dns_zone.this.name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  record              = each.value.record
  tags                = var.tags
}
