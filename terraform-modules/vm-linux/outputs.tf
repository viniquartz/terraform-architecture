output "vm_id" {
  description = "Virtual machine ID"
  value       = azurerm_linux_virtual_machine.this.id
}

output "vm_name" {
  description = "Virtual machine name"
  value       = azurerm_linux_virtual_machine.this.name
}

output "private_ip_address" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.this.private_ip_address
}

output "public_ip_address" {
  description = "Public IP address of the VM"
  value       = var.enable_public_ip ? azurerm_public_ip.this[0].ip_address : null
}

output "network_interface_id" {
  description = "Network interface ID"
  value       = azurerm_network_interface.this.id
}
