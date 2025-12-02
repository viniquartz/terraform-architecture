variable "rule_name" {
  description = "Name of the SSH security rule"
  type        = string
  default     = "allow-ssh"
}

variable "priority" {
  description = "Priority of the security rule"
  type        = number
  default     = 1001
}

variable "source_address_prefix" {
  description = "Source address prefix (CIDR or IP)"
  type        = string
  default     = "*"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "network_security_group_name" {
  description = "Network security group name"
  type        = string
}
