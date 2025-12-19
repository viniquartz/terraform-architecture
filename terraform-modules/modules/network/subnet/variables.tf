variable "name" {
  description = "Subnet name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "virtual_network_name" {
  description = "Virtual Network name"
  type        = string
}

variable "address_prefixes" {
  description = "Address prefixes for subnet"
  type        = list(string)
}

variable "service_endpoints" {
  description = "Service endpoints"
  type        = list(string)
  default     = []
}

variable "private_endpoint_network_policies_enabled" {
  description = "Enable or disable private endpoint network policies"
  type        = bool
  default     = true
}
