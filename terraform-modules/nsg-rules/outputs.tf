output "rule_ids" {
  description = "Map of rule names to their IDs"
  value       = { for k, v in azurerm_network_security_rule.this : k => v.id }
}

output "rule_names" {
  description = "List of created rule names"
  value       = [for rule in azurerm_network_security_rule.this : rule.name]
}
