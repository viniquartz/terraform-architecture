output "id" {
  description = "Public IP ID"
  value       = azurerm_public_ip.this.id
}

output "name" {
  description = "Public IP name"
  value       = azurerm_public_ip.this.name
}

output "ip_address" {
  description = "IP address value"
  value       = azurerm_public_ip.this.ip_address
}

output "fqdn" {
  description = "Fully qualified domain name"
  value       = azurerm_public_ip.this.fqdn
}
