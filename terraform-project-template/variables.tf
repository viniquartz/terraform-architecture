variable "environment" {
  description = "Environment: prd, qlt or tst"
  type        = string

  validation {
    condition     = contains(["prd", "qlt", "tst"], var.environment)
    error_message = "Environment must be: prd, qlt or tst"
  }
}

variable "project_name" {
  description = "Project name (lowercase, numbers and hyphens)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Name must contain only: a-z, 0-9 and -"
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "brazilsouth"
}

# ==============================================================================
# COMPUTE - LINUX VM VARIABLES
# ==============================================================================
variable "admin_ssh_key_linux" {
  description = "SSH public key for Linux VM admin user"
  type        = string
  sensitive   = true
}

# ==============================================================================
# COMPUTE - WINDOWS VM VARIABLES
# ==============================================================================
variable "admin_password_windows" {
  description = "Admin password for Windows VM"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.admin_password_windows) >= 12
    error_message = "Password must be at least 12 characters"
  }
}

