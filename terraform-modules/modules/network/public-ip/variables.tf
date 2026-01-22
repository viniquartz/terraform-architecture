variable "name" {
  description = "Public IP name"
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

variable "allocation_method" {
  description = "IP allocation method: Static or Dynamic"
  type        = string
  default     = "Static"

  validation {
    condition     = contains(["Static", "Dynamic"], var.allocation_method)
    error_message = "Allocation method must be Static or Dynamic"
  }
}

variable "sku" {
  description = "SKU: Basic or Standard"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.sku)
    error_message = "SKU must be Basic or Standard"
  }
}

variable "zones" {
  description = "Availability zones"
  type        = list(string)
  default     = []
}

variable "domain_name_label" {
  description = "DNS domain name label"
  type        = string
  default     = null
}

variable "idle_timeout_in_minutes" {
  description = "Idle timeout in minutes (4-30)"
  type        = number
  default     = 4

  validation {
    condition     = var.idle_timeout_in_minutes >= 4 && var.idle_timeout_in_minutes <= 30
    error_message = "Idle timeout must be between 4 and 30 minutes"
  }
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
