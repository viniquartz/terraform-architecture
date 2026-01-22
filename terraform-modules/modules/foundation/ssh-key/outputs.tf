output "id" {
  description = "SSH Key ID"
  value       = azurerm_ssh_public_key.this.id
}

output "name" {
  description = "SSH Key name"
  value       = azurerm_ssh_public_key.this.name
}

output "public_key" {
  description = "SSH public key"
  value       = azurerm_ssh_public_key.this.public_key
  sensitive   = true
}
