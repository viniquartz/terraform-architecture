# Standard resources
output "resource_group" {
  description = "Resource Group name"
  value       = local.resource_name["resource_group"]
}

output "virtual_machine" {
  description = "Virtual Machine name"
  value       = local.resource_name["virtual_machine"]
}

output "virtual_network" {
  description = "Virtual Network name"
  value       = local.resource_name["virtual_network"]
}

output "subnet" {
  description = "Subnet name"
  value       = local.resource_name["subnet"]
}

output "network_security_group" {
  description = "Network Security Group name"
  value       = local.resource_name["network_security_group"]
}

output "network_interface" {
  description = "Network Interface name"
  value       = local.resource_name["network_interface"]
}

output "public_ip" {
  description = "Public IP name"
  value       = local.resource_name["public_ip"]
}

output "disk" {
  description = "Disk name"
  value       = local.resource_name["disk"]
}

# Special cases (Azure naming restrictions)
output "storage_account" {
  description = "Storage Account name (no underscores, lowercase, max 24 chars)"
  value       = substr(local.storage_account_name, 0, 24)
}

output "key_vault" {
  description = "Key Vault name (hyphens instead of underscores, max 24 chars)"
  value       = substr(local.key_vault_name, 0, 24)
}

output "container_registry" {
  description = "Container Registry name (alphanumeric only, max 50 chars)"
  value       = substr(local.container_registry_name, 0, 50)
}

# Utilities
output "base_name" {
  description = "Base naming pattern"
  value       = local.base_name
}

output "region_abbreviation" {
  description = "Region abbreviation used"
  value       = local.region_abbr
}
