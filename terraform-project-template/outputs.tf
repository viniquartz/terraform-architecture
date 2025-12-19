# ==============================================================================
# RESOURCE GROUP OUTPUTS
# ==============================================================================
output "resource_group_name" {
  description = "Nome do Resource Group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Localização do Resource Group"
  value       = azurerm_resource_group.main.location
}

output "resource_group_id" {
  description = "ID do Resource Group"
  value       = azurerm_resource_group.main.id
}

# ==============================================================================
# NETWORK OUTPUTS
# ==============================================================================
output "vnet_name" {
  description = "Nome da Virtual Network"
  value       = module.vnet.name
}

output "vnet_id" {
  description = "ID da Virtual Network"
  value       = module.vnet.id
}

output "vnet_address_space" {
  description = "Address Space da Virtual Network"
  value       = module.vnet.address_space
}

output "subnet_app_id" {
  description = "ID da Subnet de Aplicação"
  value       = module.subnet_app.id
}

output "subnet_app_address_prefixes" {
  description = "Address Prefixes da Subnet de Aplicação"
  value       = module.subnet_app.address_prefixes
}

output "subnet_data_id" {
  description = "ID da Subnet de Dados"
  value       = module.subnet_data.id
}

output "subnet_data_address_prefixes" {
  description = "Address Prefixes da Subnet de Dados"
  value       = module.subnet_data.address_prefixes
}

output "nsg_id" {
  description = "ID do Network Security Group"
  value       = module.nsg.id
}

output "nsg_name" {
  description = "Nome do Network Security Group"
  value       = module.nsg.name
}

# ==============================================================================
# COMPUTE - LINUX VM OUTPUTS
# ==============================================================================
output "vm_linux_id" {
  description = "ID da VM Linux"
  value       = module.vm_linux.id
}

output "vm_linux_name" {
  description = "Nome da VM Linux"
  value       = module.vm_linux.name
}

output "vm_linux_private_ip" {
  description = "IP Privado da VM Linux"
  value       = module.vm_linux.private_ip_address
}

output "vm_linux_public_ip" {
  description = "IP Público da VM Linux (se aplicável)"
  value       = try(module.vm_linux.public_ip_address, null)
}

# ==============================================================================
# COMPUTE - WINDOWS VM OUTPUTS
# ==============================================================================
output "vm_windows_id" {
  description = "ID da VM Windows"
  value       = module.vm_windows.id
}

output "vm_windows_name" {
  description = "Nome da VM Windows"
  value       = module.vm_windows.name
}

output "vm_windows_private_ip" {
  description = "IP Privado da VM Windows"
  value       = module.vm_windows.private_ip_address
}

output "vm_windows_public_ip" {
  description = "IP Público da VM Windows (se aplicável)"
  value       = try(module.vm_windows.public_ip_address, null)
}

# ==============================================================================
# STORAGE OUTPUTS
# ==============================================================================
output "storage_account_name" {
  description = "Nome da Storage Account"
  value       = module.storage.name
}

output "storage_account_id" {
  description = "ID da Storage Account"
  value       = module.storage.id
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary Blob Endpoint da Storage Account"
  value       = module.storage.primary_blob_endpoint
}

