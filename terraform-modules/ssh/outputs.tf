output "rule_id" {
  description = "SSH security rule ID"
  value       = azurerm_network_security_rule.ssh.id
}

output "rule_name" {
  description = "SSH security rule name"
  value       = azurerm_network_security_rule.ssh.name
}
