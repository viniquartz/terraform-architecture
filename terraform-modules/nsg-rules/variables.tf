variable "resource_group_name" {
  description = "Name of the resource group where the NSG is located"
  type        = string
}

variable "network_security_group_name" {
  description = "Name of the network security group to add rules to"
  type        = string
}

variable "security_rules" {
  description = "List of security rules to create"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))

  validation {
    condition = alltrue([
      for rule in var.security_rules : contains(["Inbound", "Outbound"], rule.direction)
    ])
    error_message = "Direction must be either 'Inbound' or 'Outbound'"
  }

  validation {
    condition = alltrue([
      for rule in var.security_rules : contains(["Allow", "Deny"], rule.access)
    ])
    error_message = "Access must be either 'Allow' or 'Deny'"
  }

  validation {
    condition = alltrue([
      for rule in var.security_rules : contains(["Tcp", "Udp", "Icmp", "Esp", "Ah", "*"], rule.protocol)
    ])
    error_message = "Protocol must be one of: Tcp, Udp, Icmp, Esp, Ah, or *"
  }

  validation {
    condition = alltrue([
      for rule in var.security_rules : rule.priority >= 100 && rule.priority <= 4096
    ])
    error_message = "Priority must be between 100 and 4096"
  }
}
