output "id" {
  description = "Subnet ID"
  value       = azurerm_subnet.main.id
}

output "name" {
  description = "Subnet name"
  value       = azurerm_subnet.main.name
}

output "address_prefixes" {
  description = "Subnet address prefixes"
  value       = azurerm_subnet.main.address_prefixes
}
