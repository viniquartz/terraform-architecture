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

# Optional: SSH key for VM module (uncomment if using VMs)
# variable "admin_ssh_key" {
#   description = "SSH public key for VM admin user"
#   type        = string
#   sensitive   = true
# }
