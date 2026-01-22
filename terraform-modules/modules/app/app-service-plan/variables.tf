variable "name" {
  description = "App Service Plan name"
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

variable "os_type" {
  description = "OS type (Windows or Linux)"
  type        = string

  validation {
    condition     = contains(["Windows", "Linux"], var.os_type)
    error_message = "OS type must be Windows or Linux."
  }
}

variable "sku_name" {
  description = "SKU name (B1, B2, B3, S1, S2, S3, P1v2, P2v2, P3v2, P1v3, P2v3, P3v3, I1v2, I2v2, I3v2, Y1)"
  type        = string
}

variable "app_service_environment_id" {
  description = "App Service Environment ID for Isolated SKUs"
  type        = string
  default     = null
}

variable "maximum_elastic_worker_count" {
  description = "Maximum elastic worker count for Premium plans"
  type        = number
  default     = null
}

variable "worker_count" {
  description = "Number of workers (instances)"
  type        = number
  default     = null
}

variable "per_site_scaling_enabled" {
  description = "Enable per-site scaling"
  type        = bool
  default     = false
}

variable "zone_balancing_enabled" {
  description = "Enable zone balancing (requires Premium v2/v3)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
