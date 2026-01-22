variable "name" {
  description = "Managed Disk name"
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

variable "storage_account_type" {
  description = "Storage type (Standard_LRS, Premium_LRS, StandardSSD_LRS, UltraSSD_LRS, Premium_ZRS, StandardSSD_ZRS)"
  type        = string
  default     = "Premium_LRS"

  validation {
    condition     = contains(["Standard_LRS", "Premium_LRS", "StandardSSD_LRS", "UltraSSD_LRS", "Premium_ZRS", "StandardSSD_ZRS"], var.storage_account_type)
    error_message = "Storage account type must be Standard_LRS, Premium_LRS, StandardSSD_LRS, UltraSSD_LRS, Premium_ZRS, or StandardSSD_ZRS."
  }
}

variable "create_option" {
  description = "Creation method (Empty, Copy, FromImage, Import, Restore, Upload)"
  type        = string
  default     = "Empty"

  validation {
    condition     = contains(["Empty", "Copy", "FromImage", "Import", "Restore", "Upload"], var.create_option)
    error_message = "Create option must be Empty, Copy, FromImage, Import, Restore, or Upload."
  }
}

variable "disk_size_gb" {
  description = "Disk size in GB"
  type        = number
  default     = 128
}

variable "os_type" {
  description = "OS type for OS disk (Linux or Windows)"
  type        = string
  default     = null
}

variable "source_resource_id" {
  description = "Source resource ID for Copy/Restore"
  type        = string
  default     = null
}

variable "source_uri" {
  description = "Source VHD URI for Import"
  type        = string
  default     = null
}

variable "storage_account_id" {
  description = "Storage account ID for Import"
  type        = string
  default     = null
}

variable "image_reference_id" {
  description = "Image ID for FromImage"
  type        = string
  default     = null
}

variable "gallery_image_reference_id" {
  description = "Gallery image ID for FromImage"
  type        = string
  default     = null
}

variable "hyper_v_generation" {
  description = "Hyper-V generation (V1 or V2)"
  type        = string
  default     = null
}

variable "on_demand_bursting_enabled" {
  description = "Enable on-demand bursting"
  type        = bool
  default     = false
}

variable "trusted_launch_enabled" {
  description = "Enable Trusted Launch"
  type        = bool
  default     = false
}

variable "security_type" {
  description = "Security type (TrustedLaunch or ConfidentialVM_DiskEncryptedWithCustomerKey)"
  type        = string
  default     = null
}

variable "secure_vm_disk_encryption_set_id" {
  description = "Disk Encryption Set ID for ConfidentialVM"
  type        = string
  default     = null
}

variable "disk_encryption_set_id" {
  description = "Disk Encryption Set ID"
  type        = string
  default     = null
}

variable "disk_iops_read_write" {
  description = "IOPS for Premium/Ultra disks"
  type        = number
  default     = null
}

variable "disk_mbps_read_write" {
  description = "Throughput in MB/s for Premium/Ultra disks"
  type        = number
  default     = null
}

variable "disk_iops_read_only" {
  description = "Read-only IOPS"
  type        = number
  default     = null
}

variable "disk_mbps_read_only" {
  description = "Read-only throughput in MB/s"
  type        = number
  default     = null
}

variable "upload_size_bytes" {
  description = "Upload size in bytes for Upload create_option"
  type        = number
  default     = null
}

variable "tier" {
  description = "Performance tier for Premium SSD"
  type        = string
  default     = null
}

variable "max_shares" {
  description = "Max number of VMs sharing disk"
  type        = number
  default     = null
}

variable "zone" {
  description = "Availability zone"
  type        = string
  default     = null
}

variable "network_access_policy" {
  description = "Network access policy (AllowAll, AllowPrivate, DenyAll)"
  type        = string
  default     = null
}

variable "disk_access_id" {
  description = "Disk Access ID for private links"
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "edge_zone" {
  description = "Edge zone"
  type        = string
  default     = null
}

variable "encryption_settings" {
  description = "Azure Disk Encryption settings (legacy)"
  type = object({
    disk_encryption_key = optional(object({
      secret_url      = string
      source_vault_id = string
    }))
    key_encryption_key = optional(object({
      key_url         = string
      source_vault_id = string
    }))
  })
  default = null
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
