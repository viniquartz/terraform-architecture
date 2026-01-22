output "id" {
  description = "DNS Zone ID"
  value       = azurerm_dns_zone.this.id
}

output "name" {
  description = "DNS Zone name"
  value       = azurerm_dns_zone.this.name
}

output "name_servers" {
  description = "Name servers for the DNS zone"
  value       = azurerm_dns_zone.this.name_servers
}
