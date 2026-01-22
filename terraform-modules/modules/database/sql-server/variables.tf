variable "name" {
  description = "SQL Server name (globally unique)"
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

variable "version" {
  description = "SQL Server version (2.0 or 12.0)"
  type        = string
  default     = "12.0"
}

variable "administrator_login" {
  description = "SQL admin username (required unless using Azure AD only)"
  type        = string
  default     = null
}

variable "administrator_login_password" {
  description = "SQL admin password (required unless using Azure AD only)"
  type        = string
  sensitive   = true
  default     = null
}

variable "minimum_tls_version" {
  description = "Minimum TLS version (1.0, 1.1, 1.2)"
  type        = string
  default     = "1.2"
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "outbound_network_restriction_enabled" {
  description = "Restrict outbound network access"
  type        = bool
  default     = false
}

variable "primary_user_assigned_identity_id" {
  description = "Primary User Assigned Identity ID"
  type        = string
  default     = null
}

variable "transparent_data_encryption_key_vault_key_id" {
  description = "Key Vault key ID for TDE"
  type        = string
  default     = null
}

variable "azuread_administrator" {
  description = "Azure AD administrator configuration"
  type = object({
    login_username              = string
    object_id                   = string
    tenant_id                   = optional(string)
    azuread_authentication_only = optional(bool, false)
  })
  default = null
}

variable "identity_type" {
  description = "Managed identity type (SystemAssigned, UserAssigned)"
  type        = string
  default     = null

  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "Identity type must be SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'."
  }
}

variable "identity_ids" {
  description = "User Assigned Identity IDs"
  type        = list(string)
  default     = null
}

variable "firewall_rules" {
  description = "Firewall rules map"
  type = map(object({
    start_ip = string
    end_ip   = string
  }))
  default = {}
}

variable "vnet_rules" {
  description = "VNet rules map"
  type = map(object({
    subnet_id = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
