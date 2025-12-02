output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "Virtual network ID"
  value       = module.vnet.vnet_id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = module.subnet.subnet_id
}

output "nsg_id" {
  description = "Network security group ID"
  value       = module.nsg.nsg_id
}

output "vm_id" {
  description = "Virtual machine ID"
  value       = module.vm.vm_id
}

output "vm_private_ip" {
  description = "VM private IP address"
  value       = module.vm.private_ip_address
}

output "vm_public_ip" {
  description = "VM public IP address"
  value       = module.vm.public_ip_address
}
