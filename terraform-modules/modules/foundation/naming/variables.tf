variable "environment" {
  description = "Environment (prd, qlt, tst)"
  type        = string

  validation {
    condition     = contains(["prd", "qlt", "tst"], var.environment)
    error_message = "Environment must be prd, qlt, or tst"
  }
}

variable "project_name" {
  description = "Project name (e.g., datalake, powerbi)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,20}$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric, 2-20 chars"
  }
}

variable "project_version" {
  description = "Project version (e.g., 01, 02)"
  type        = string
  default     = "01"

  validation {
    condition     = can(regex("^[0-9]{2}$", var.project_version))
    error_message = "Project version must be 2 digits (e.g., 01, 02)"
  }
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "suffix" {
  description = "Optional suffix to append (e.g., for multiple instances)"
  type        = string
  default     = ""
}

variable "purpose" {
  description = "Optional purpose description (e.g., web, api, db)"
  type        = string
  default     = ""
}
