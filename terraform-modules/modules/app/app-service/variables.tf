variable "name" {
  description = "App Service name"
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

variable "service_plan_id" {
  description = "App Service Plan ID"
  type        = string
}

variable "os_type" {
  description = "OS type (Linux or Windows)"
  type        = string

  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "OS type must be Linux or Windows."
  }
}

variable "https_only" {
  description = "HTTPS only"
  type        = bool
  default     = true
}

variable "client_affinity_enabled" {
  description = "Enable client affinity (sticky sessions)"
  type        = bool
  default     = false
}

variable "enabled" {
  description = "Enable app"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "virtual_network_subnet_id" {
  description = "VNet integration subnet ID"
  type        = string
  default     = null
}

variable "always_on" {
  description = "Keep app loaded (not available for Free/Shared)"
  type        = bool
  default     = true
}

variable "ftps_state" {
  description = "FTPS state (Disabled, FtpsOnly, AllAllowed)"
  type        = string
  default     = "Disabled"
}

variable "health_check_path" {
  description = "Health check endpoint path"
  type        = string
  default     = null
}

variable "health_check_eviction_time_in_min" {
  description = "Health check eviction time in minutes"
  type        = number
  default     = null
}

variable "http2_enabled" {
  description = "Enable HTTP/2"
  type        = bool
  default     = true
}

variable "minimum_tls_version" {
  description = "Minimum TLS version (1.0, 1.1, 1.2)"
  type        = string
  default     = "1.2"
}

variable "remote_debugging_enabled" {
  description = "Enable remote debugging"
  type        = bool
  default     = false
}

variable "scm_minimum_tls_version" {
  description = "SCM minimum TLS version"
  type        = string
  default     = "1.2"
}

variable "vnet_route_all_enabled" {
  description = "Route all traffic through VNet"
  type        = bool
  default     = false
}

variable "websockets_enabled" {
  description = "Enable WebSockets"
  type        = bool
  default     = false
}

variable "container_registry_use_managed_identity" {
  description = "Use Managed Identity for ACR"
  type        = bool
  default     = false
}

variable "application_stack" {
  description = "Application stack configuration"
  type = object({
    # Linux-specific
    docker_image     = optional(string)
    docker_image_tag = optional(string)
    dotnet_version   = optional(string)
    java_version     = optional(string)
    node_version     = optional(string)
    php_version      = optional(string)
    python_version   = optional(string)
    ruby_version     = optional(string)
    # Windows-specific
    current_stack             = optional(string)
    python                    = optional(bool)
    docker_container_name     = optional(string)
    docker_container_registry = optional(string)
  })
  default = null
}

variable "identity_type" {
  description = "Managed identity type"
  type        = string
  default     = null

  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "Identity type must be SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'."
  }
}

variable "identity_ids" {
  description = "User Assigned Identity IDs"
  type        = list(string)
  default     = null
}

variable "app_settings" {
  description = "App settings (environment variables)"
  type        = map(string)
  default     = {}
}

variable "connection_strings" {
  description = "Connection strings"
  type = map(object({
    type  = string
    value = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
