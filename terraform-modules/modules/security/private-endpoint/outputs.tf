output "id" {
  description = "Private Endpoint ID"
  value       = azurerm_private_endpoint.this.id
}

output "name" {
  description = "Private Endpoint name"
  value       = azurerm_private_endpoint.this.name
}

output "private_ip_address" {
  description = "Private IP address"
  value       = try(azurerm_private_endpoint.this.private_service_connection[0].private_ip_address, null)
}

output "network_interface_id" {
  description = "Network Interface ID"
  value       = try(azurerm_private_endpoint.this.network_interface[0].id, null)
}
