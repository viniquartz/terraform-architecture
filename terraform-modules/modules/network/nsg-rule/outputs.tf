output "id" {
  description = "Security rule ID"
  value       = azurerm_network_security_rule.main.id
}

output "name" {
  description = "Security rule name"
  value       = azurerm_network_security_rule.main.name
}
