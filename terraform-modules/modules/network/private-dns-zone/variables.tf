variable "name" {
  description = "Private DNS Zone name (e.g., privatelink.database.windows.net)"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "virtual_network_links" {
  description = "Map of VNet links"
  type = map(object({
    virtual_network_id   = string
    registration_enabled = bool
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
