output "id" {
  description = "Managed Disk ID"
  value       = azurerm_managed_disk.this.id
}

output "name" {
  description = "Managed Disk name"
  value       = azurerm_managed_disk.this.name
}
