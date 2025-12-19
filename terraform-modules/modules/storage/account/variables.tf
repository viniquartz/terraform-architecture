variable "name" {
  description = "Storage Account name"
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

variable "account_tier" {
  description = "Storage Account tier (Standard, Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be Standard or Premium."
  }
}

variable "account_replication_type" {
  description = "Storage Account replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.account_replication_type)
    error_message = "Invalid replication type."
  }
}

variable "account_kind" {
  description = "Storage Account kind (StorageV2, BlobStorage, BlockBlobStorage, FileStorage)"
  type        = string
  default     = "StorageV2"
}

variable "access_tier" {
  description = "Access tier for BlobStorage, StorageV2 and FileStorage accounts (Hot, Cool)"
  type        = string
  default     = "Hot"

  validation {
    condition     = contains(["Hot", "Cool"], var.access_tier)
    error_message = "Access tier must be Hot or Cool."
  }
}

variable "min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "TLS1_2"
}

variable "enable_https_traffic_only" {
  description = "Enable HTTPS traffic only"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access (disable for production security)"
  type        = bool
  default     = true
}

variable "network_rules" {
  description = "Network rules for storage account"
  type = object({
    default_action             = string
    bypass                     = list(string)
    ip_rules                   = list(string)
    virtual_network_subnet_ids = list(string)
  })
  default = null
}

variable "blob_properties" {
  description = "Blob properties configuration"
  type = object({
    versioning_enabled            = bool
    change_feed_enabled           = bool
    last_access_time_enabled      = bool
    delete_retention_days         = number
    container_delete_retention_days = number
  })
  default = {
    versioning_enabled            = false
    change_feed_enabled           = false
    last_access_time_enabled      = false
    delete_retention_days         = 7
    container_delete_retention_days = 7
  }
}

variable "enable_advanced_threat_protection" {
  description = "Enable Advanced Threat Protection (additional cost)"
  type        = bool
  default     = false
}

variable "enable_infrastructure_encryption" {
  description = "Enable infrastructure encryption (additional security, cannot be changed after creation)"
  type        = bool
  default     = false
}

variable "containers" {
  description = "Map of containers to create with their access levels"
  type = map(object({
    access_type = string
  }))
  default = {}
}

variable "shares" {
  description = "Map of file shares to create"
  type = map(object({
    quota = number
  }))
  default = {}
}

variable "queues" {
  description = "List of queues to create"
  type        = list(string)
  default     = []
}

variable "tables" {
  description = "List of tables to create"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
