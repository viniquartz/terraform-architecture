output "id" {
  description = "AKS cluster ID"
  value       = azurerm_kubernetes_cluster.this.id
}

output "name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.this.name
}

output "fqdn" {
  description = "FQDN"
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "kube_config_raw" {
  description = "Raw kubeconfig"
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "kube_config" {
  description = "Kubeconfig"
  value       = azurerm_kubernetes_cluster.this.kube_config
  sensitive   = true
}

output "identity_principal_id" {
  description = "System Assigned Identity Principal ID"
  value       = try(azurerm_kubernetes_cluster.this.identity[0].principal_id, null)
}

output "kubelet_identity" {
  description = "Kubelet identity"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity
}
