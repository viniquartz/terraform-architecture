output "vm_id" {
  description = "The ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.this.id
}

output "vm_name" {
  description = "The name of the virtual machine"
  value       = azurerm_linux_virtual_machine.this.name
}

output "private_ip_address" {
  description = "The private IP address of the VM"
  value       = azurerm_network_interface.this.private_ip_address
}

output "public_ip_address" {
  description = "The public IP address of the VM (null if public IP is disabled)"
  value       = var.enable_public_ip ? azurerm_public_ip.this[0].ip_address : null
}

output "network_interface_id" {
  description = "The ID of the network interface"
  value       = azurerm_network_interface.this.id
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = var.enable_public_ip ? "ssh ${var.admin_username}@${azurerm_public_ip.this[0].ip_address}" : "ssh ${var.admin_username}@${azurerm_network_interface.this.private_ip_address}"
}

output "admin_username" {
  description = "The admin username for the VM"
  value       = var.admin_username
}
