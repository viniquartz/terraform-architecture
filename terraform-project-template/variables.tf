variable "environment" {
  description = "Ambiente: prd, qlt ou tst"
  type        = string

  validation {
    condition     = contains(["prd", "qlt", "tst"], var.environment)
    error_message = "Ambiente deve ser: prd, qlt ou tst"
  }
}

variable "project_name" {
  description = "Nome do projeto (minusculas, numeros e hifens)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Nome deve conter apenas: a-z, 0-9 e -"
  }
}

variable "location" {
  description = "Regiao Azure"
  type        = string
  default     = "brazilsouth"
}
