variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string

  validation {
    condition     = length(var.vnet_name) > 0 && length(var.vnet_name) <= 64
    error_message = "VNET name must be between 1 and 64 characters"
  }
}

variable "location" {
  description = "Azure region where the virtual network will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where the virtual network will be created"
  type        = string
}

variable "address_space" {
  description = "Address space (CIDR blocks) for the virtual network"
  type        = list(string)

  validation {
    condition = alltrue([
      for cidr in var.address_space : can(cidrhost(cidr, 0))
    ])
    error_message = "All address spaces must be valid CIDR blocks"
  }
}

variable "tags" {
  description = "Map of tags to apply to the virtual network"
  type        = map(string)
  default     = {}

  validation {
    condition     = contains(keys(var.tags), "Environment") || length(var.tags) == 0
    error_message = "Tags must include 'Environment' key when tags are provided"
  }
}
