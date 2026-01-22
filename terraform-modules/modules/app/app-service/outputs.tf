output "id" {
  description = "App Service ID"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.this[0].id : azurerm_windows_web_app.this[0].id
}

output "name" {
  description = "App Service name"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.this[0].name : azurerm_windows_web_app.this[0].name
}

output "default_hostname" {
  description = "Default hostname"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.this[0].default_hostname : azurerm_windows_web_app.this[0].default_hostname
}

output "outbound_ip_addresses" {
  description = "Outbound IP addresses"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.this[0].outbound_ip_addresses : azurerm_windows_web_app.this[0].outbound_ip_addresses
}

output "identity_principal_id" {
  description = "System Assigned Identity Principal ID"
  value       = var.os_type == "Linux" ? try(azurerm_linux_web_app.this[0].identity[0].principal_id, null) : try(azurerm_windows_web_app.this[0].identity[0].principal_id, null)
}
