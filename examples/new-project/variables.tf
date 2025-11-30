# Variáveis do projeto

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name deve conter apenas letras minúsculas, números e hífens."
  }
}

variable "environment" {
  description = "Ambiente (development, testing, staging, production)"
  type        = string
  
  validation {
    condition     = contains(["development", "testing", "staging", "production"], var.environment)
    error_message = "Environment deve ser: development, testing, staging ou production."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "vnet_address_space" {
  description = "Address space da Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Subnets a serem criadas"
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegations       = optional(list(string), [])
    security_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), [])
  }))
  
  default = {
    subnet-web = {
      address_prefixes = ["10.0.1.0/24"]
      security_rules = [
        {
          name                       = "AllowHTTP"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
        {
          name                       = "AllowHTTPS"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]
    }
    subnet-app = {
      address_prefixes = ["10.0.2.0/24"]
      security_rules   = []
    }
    subnet-data = {
      address_prefixes = ["10.0.3.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
      security_rules   = []
    }
  }
}

variable "tags" {
  description = "Tags adicionais para os recursos"
  type        = map(string)
  default     = {}
}
