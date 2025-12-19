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

output "network_interface_id" {
  description = "Network Interface ID"
  value       = azurerm_network_interface.main.id
}
