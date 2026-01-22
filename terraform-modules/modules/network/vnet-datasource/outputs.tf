output "id" {
  description = "Virtual Network ID"
  value       = data.azurerm_virtual_network.this.id
}

output "name" {
  description = "Virtual Network name"
  value       = data.azurerm_virtual_network.this.name
}

output "address_space" {
  description = "Address space"
  value       = data.azurerm_virtual_network.this.address_space
}

output "subnets" {
  description = "Subnet names"
  value       = data.azurerm_virtual_network.this.subnets
}

output "location" {
  description = "Location"
  value       = data.azurerm_virtual_network.this.location
}
