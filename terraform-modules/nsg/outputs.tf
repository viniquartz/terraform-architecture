output "nsg_id" {
  description = "Network security group ID"
  value       = azurerm_network_security_group.this.id
}

output "nsg_name" {
  description = "Network security group name"
  value       = azurerm_network_security_group.this.name
}
