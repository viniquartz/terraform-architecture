output "id" {
  description = "Private DNS Zone ID"
  value       = azurerm_private_dns_zone.this.id
}

output "name" {
  description = "Private DNS Zone name"
  value       = azurerm_private_dns_zone.this.name
}

output "vnet_link_ids" {
  description = "VNet link IDs"
  value       = { for k, v in azurerm_private_dns_zone_virtual_network_link.links : k => v.id }
}
