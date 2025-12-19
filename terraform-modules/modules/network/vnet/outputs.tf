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
