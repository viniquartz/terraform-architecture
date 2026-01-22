variable "name" {
  description = "Key Vault name (3-24 chars, alphanumeric and hyphens)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,24}$", var.name))
    error_message = "Key Vault name must be 3-24 characters, alphanumeric and hyphens only"
  }
}

variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
}

variable "sku_name" {
  description = "SKU: standard or premium"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU must be standard or premium"
  }
}

variable "enabled_for_deployment" {
  description = "Enable Azure Virtual Machines to retrieve certificates"
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Enable Azure Disk Encryption to retrieve secrets"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Enable Azure Resource Manager to retrieve secrets"
  type        = bool
  default     = false
}

variable "enable_rbac_authorization" {
  description = "Use Azure RBAC for authorization instead of access policies"
  type        = bool
  default     = true
}

variable "purge_protection_enabled" {
  description = "Enable purge protection (cannot be disabled once enabled)"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention period in days (7-90)"
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Retention days must be between 7 and 90"
  }
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "network_acls" {
  description = "Network ACLs configuration"
  type = object({
    bypass                     = string
    default_action             = string
    ip_rules                   = list(string)
    virtual_network_subnet_ids = list(string)
  })
  default = null
}

variable "access_policies" {
  description = "Access policies (used when enable_rbac_authorization = false)"
  type = map(object({
    object_id               = string
    key_permissions         = list(string)
    secret_permissions      = list(string)
    certificate_permissions = list(string)
    storage_permissions     = list(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
