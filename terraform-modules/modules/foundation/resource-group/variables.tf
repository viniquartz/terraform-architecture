variable "name" {
  description = "Resource Group name"
  type        = string
}

variable "location" {
  description = "Azure region (required only when creating new resource group)"
  type        = string
  default     = null
}

variable "create" {
  description = "Create new resource group (true) or use existing (false)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply (only for new resource groups)"
  type        = map(string)
  default     = {}
}
