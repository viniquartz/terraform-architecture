output "id" {
  description = "Subnet ID"
  value       = data.azurerm_subnet.this.id
}

output "name" {
  description = "Subnet name"
  value       = data.azurerm_subnet.this.name
}

output "address_prefixes" {
  description = "Address prefixes"
  value       = data.azurerm_subnet.this.address_prefixes
}

output "virtual_network_name" {
  description = "Virtual Network name"
  value       = data.azurerm_subnet.this.virtual_network_name
}
