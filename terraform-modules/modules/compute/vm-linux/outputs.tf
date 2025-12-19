output "id" {
  description = "VM ID"
  value       = azurerm_linux_virtual_machine.main.id
}

output "name" {
  description = "VM name"
  value       = azurerm_linux_virtual_machine.main.name
}

output "private_ip_address" {
  description = "VM private IP address"
  value       = azurerm_network_interface.main.private_ip_address
}

output "public_ip_address" {
  description = "VM public IP address (if assigned)"
  value       = var.public_ip_id != null ? azurerm_network_interface.main.ip_configuration[0].public_ip_address_id : null
}

output "network_interface_id" {
  description = "Network Interface ID"
  value       = azurerm_network_interface.main.id
}
