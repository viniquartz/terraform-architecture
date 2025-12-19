output "id" {
  description = "VNet ID"
  value       = azurerm_virtual_network.main.id
}

output "name" {
  description = "VNet name"
  value       = azurerm_virtual_network.main.name
}

output "address_space" {
  description = "VNet address space"
  value       = azurerm_virtual_network.main.address_space
}

output "subnet_ids" {
  description = "Map of subnet names to IDs"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "subnet_names" {
  description = "Map of subnet keys to names"
  value       = { for k, v in azurerm_subnet.subnets : k => v.name }
}
