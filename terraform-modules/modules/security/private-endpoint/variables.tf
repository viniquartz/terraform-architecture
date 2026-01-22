variable "name" {
  description = "Private Endpoint name"
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

variable "subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
}

variable "private_connection_resource_id" {
  description = "Resource ID to connect to"
  type        = string
}

variable "subresource_names" {
  description = "Subresource names (e.g., ['sqlServer'] for SQL, ['vault'] for Key Vault)"
  type        = list(string)
}

variable "is_manual_connection" {
  description = "Require manual approval"
  type        = bool
  default     = false
}

variable "request_message" {
  description = "Request message for manual connection"
  type        = string
  default     = null
}

variable "private_dns_zone_ids" {
  description = "Private DNS Zone IDs for DNS integration"
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
