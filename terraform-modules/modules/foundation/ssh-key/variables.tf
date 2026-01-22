variable "name" {
  description = "SSH Key name"
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

variable "public_key" {
  description = "SSH public key content"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
