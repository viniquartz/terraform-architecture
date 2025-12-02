output "subnet_id" {
  description = "Subnet ID"
  value       = azurerm_subnet.this.id
}

output "subnet_name" {
  description = "Subnet name"
  value       = azurerm_subnet.this.name
}

output "address_prefixes" {
  description = "Address prefixes of the subnet"
  value       = azurerm_subnet.this.address_prefixes
}
