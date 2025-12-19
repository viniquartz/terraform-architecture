output "id" {
  description = "Storage Account ID"
  value       = azurerm_storage_account.main.id
}

output "name" {
  description = "Storage Account name"
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_file_endpoint" {
  description = "Primary file endpoint"
  value       = azurerm_storage_account.main.primary_file_endpoint
}

output "primary_queue_endpoint" {
  description = "Primary queue endpoint"
  value       = azurerm_storage_account.main.primary_queue_endpoint
}

output "primary_table_endpoint" {
  description = "Primary table endpoint"
  value       = azurerm_storage_account.main.primary_table_endpoint
}

output "primary_access_key" {
  description = "Primary access key"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "Secondary access key"
  value       = azurerm_storage_account.main.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "container_ids" {
  description = "Map of container names to IDs"
  value       = { for k, v in azurerm_storage_container.containers : k => v.id }
}

output "share_ids" {
  description = "Map of share names to IDs"
  value       = { for k, v in azurerm_storage_share.shares : k => v.id }
}

output "queue_ids" {
  description = "Map of queue names to IDs"
  value       = { for k, v in azurerm_storage_queue.queues : k => v.id }
}

output "table_ids" {
  description = "Map of table names to IDs"
  value       = { for k, v in azurerm_storage_table.tables : k => v.id }
}
