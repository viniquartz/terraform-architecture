variable "prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name (prd or non-prd)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for virtual network"
  type        = list(string)
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for subnet"
  type        = list(string)
}

variable "ssh_rule_priority" {
  description = "Priority for SSH security rule"
  type        = number
  default     = 1001
}

variable "ssh_source_address_prefix" {
  description = "Source address prefix for SSH access"
  type        = string
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
}

variable "admin_username" {
  description = "Admin username for VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "enable_public_ip" {
  description = "Enable public IP for VM"
  type        = bool
}

variable "os_disk_type" {
  description = "OS disk storage type"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
