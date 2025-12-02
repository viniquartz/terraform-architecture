output "vnet_id" {
  description = "Virtual network ID"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Virtual network name"
  value       = azurerm_virtual_network.this.name
}

output "address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.this.address_space
}
