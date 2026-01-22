variable "name" {
  description = "AKS cluster name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "SKU tier (Free, Standard, Premium)"
  type        = string
  default     = "Free"
}

variable "automatic_channel_upgrade" {
  description = "Upgrade channel (patch, rapid, stable, node-image)"
  type        = string
  default     = null
}

variable "node_resource_group" {
  description = "Node resource group name"
  type        = string
  default     = null
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = false
}

variable "role_based_access_control_enabled" {
  description = "Enable RBAC"
  type        = bool
  default     = true
}

variable "default_node_pool" {
  description = "Default node pool configuration"
  type = object({
    name                         = string
    vm_size                      = string
    node_count                   = optional(number)
    enable_auto_scaling          = optional(bool, false)
    min_count                    = optional(number)
    max_count                    = optional(number)
    max_pods                     = optional(number)
    os_disk_size_gb              = optional(number)
    os_disk_type                 = optional(string, "Managed")
    vnet_subnet_id               = optional(string)
    zones                        = optional(list(string))
    node_labels                  = optional(map(string))
    node_taints                  = optional(list(string))
    only_critical_addons_enabled = optional(bool, false)
  })
}

variable "identity_type" {
  description = "Managed identity type (SystemAssigned or UserAssigned)"
  type        = string
  default     = "SystemAssigned"
}

variable "identity_ids" {
  description = "User Assigned Identity IDs"
  type        = list(string)
  default     = null
}

variable "network_profile" {
  description = "Network profile configuration"
  type = object({
    network_plugin    = string
    network_policy    = optional(string)
    dns_service_ip    = optional(string)
    service_cidr      = optional(string)
    load_balancer_sku = optional(string, "standard")
    outbound_type     = optional(string, "loadBalancer")
  })
  default = {
    network_plugin = "azure"
  }
}

variable "azure_ad_rbac" {
  description = "Azure AD RBAC configuration"
  type = object({
    managed                = optional(bool, true)
    azure_rbac_enabled     = optional(bool, true)
    admin_group_object_ids = optional(list(string))
    tenant_id              = optional(string)
  })
  default = null
}

variable "key_vault_secrets_provider_enabled" {
  description = "Enable Key Vault Secrets Provider"
  type        = bool
  default     = false
}

variable "key_vault_secrets_rotation_enabled" {
  description = "Enable secrets rotation"
  type        = bool
  default     = false
}

variable "key_vault_secrets_rotation_interval" {
  description = "Secrets rotation interval"
  type        = string
  default     = "2m"
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for monitoring"
  type        = string
  default     = null
}

variable "additional_node_pools" {
  description = "Additional node pools"
  type = map(object({
    vm_size             = string
    node_count          = optional(number)
    enable_auto_scaling = optional(bool, false)
    min_count           = optional(number)
    max_count           = optional(number)
    max_pods            = optional(number)
    os_disk_size_gb     = optional(number)
    os_disk_type        = optional(string, "Managed")
    os_type             = optional(string, "Linux")
    vnet_subnet_id      = optional(string)
    zones               = optional(list(string))
    node_labels         = optional(map(string))
    node_taints         = optional(list(string))
    mode                = optional(string, "User")
    tags                = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
