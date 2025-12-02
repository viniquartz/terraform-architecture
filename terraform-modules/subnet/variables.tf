variable "subnet_name" {
  description = "Name of the subnet"
  type        = string

  validation {
    condition     = length(var.subnet_name) > 0 && length(var.subnet_name) <= 80
    error_message = "Subnet name must be between 1 and 80 characters"
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the subnet will be created"
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the virtual network where the subnet will be created"
  type        = string
}

variable "address_prefixes" {
  description = "Address prefixes (CIDR blocks) for the subnet"
  type        = list(string)

  validation {
    condition = alltrue([
      for cidr in var.address_prefixes : can(cidrhost(cidr, 0))
    ])
    error_message = "All address prefixes must be valid CIDR blocks"
  }
}

variable "service_endpoints" {
  description = "List of service endpoints to associate with the subnet (e.g., Microsoft.Storage, Microsoft.Sql, Microsoft.KeyVault)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for se in var.service_endpoints : can(regex("^Microsoft\\\\.", se))
    ])
    error_message = "Service endpoints must start with 'Microsoft.'"
  }
}
