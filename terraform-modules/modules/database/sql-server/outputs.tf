output "id" {
  description = "SQL Server ID"
  value       = azurerm_mssql_server.this.id
}

output "name" {
  description = "SQL Server name"
  value       = azurerm_mssql_server.this.name
}

output "fqdn" {
  description = "Fully qualified domain name"
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "identity_principal_id" {
  description = "System Assigned Identity Principal ID"
  value       = try(azurerm_mssql_server.this.identity[0].principal_id, null)
}

output "identity_tenant_id" {
  description = "System Assigned Identity Tenant ID"
  value       = try(azurerm_mssql_server.this.identity[0].tenant_id, null)
}
