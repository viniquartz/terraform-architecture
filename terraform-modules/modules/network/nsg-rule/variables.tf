variable "name" {
  description = "Security rule name"
  type        = string
}

variable "priority" {
  description = "Rule priority (100-4096)"
  type        = number
  
  validation {
    condition     = var.priority >= 100 && var.priority <= 4096
    error_message = "Priority must be between 100 and 4096"
  }
}

variable "direction" {
  description = "Inbound or Outbound"
  type        = string
  
  validation {
    condition     = contains(["Inbound", "Outbound"], var.direction)
    error_message = "Direction must be Inbound or Outbound"
  }
}

variable "access" {
  description = "Allow or Deny"
  type        = string
  
  validation {
    condition     = contains(["Allow", "Deny"], var.access)
    error_message = "Access must be Allow or Deny"
  }
}

variable "protocol" {
  description = "Tcp, Udp, Icmp or *"
  type        = string
}

variable "source_port_range" {
  description = "Source port range"
  type        = string
  default     = "*"
}

variable "destination_port_range" {
  description = "Destination port range"
  type        = string
}

variable "source_address_prefix" {
  description = "Source address prefix"
  type        = string
  default     = "*"
}

variable "destination_address_prefix" {
  description = "Destination address prefix"
  type        = string
  default     = "*"
}

variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "network_security_group_name" {
  description = "NSG name"
  type        = string
}
