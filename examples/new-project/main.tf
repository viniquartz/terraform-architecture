# Template para novos projetos Terraform
# Copie esta estrutura e ajuste conforme necessário

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-prod-eastus"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "project-name/environment/terraform.tfstate"  # Ajuste
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

# Data sources
data "azurerm_client_config" "current" {}

# Variáveis locais
locals {
  project     = var.project_name
  environment = var.environment
  location    = var.location
  
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    }
  )
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.project}-${local.environment}-${local.location}"
  location = local.location
  tags     = local.common_tags
}

# Virtual Network usando módulo
module "network" {
  source = "git::https://gitlab.com/org/terraform-azure-modules.git//networking/virtual-network?ref=v1.0.0"
  
  name                = "vnet-${local.project}-${local.environment}-${local.location}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = var.vnet_address_space
  
  tags = local.common_tags
}

# Subnet usando módulo
module "subnet" {
  source = "git::https://gitlab.com/org/terraform-azure-modules.git//networking/subnet?ref=v1.0.0"
  
  for_each = var.subnets
  
  name                 = each.key
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = module.network.vnet_name
  address_prefixes     = each.value.address_prefixes
  
  # Delegações (opcional)
  delegations = lookup(each.value, "delegations", [])
  
  # Service endpoints (opcional)
  service_endpoints = lookup(each.value, "service_endpoints", [])
}

# NSG usando módulo
module "nsg" {
  source = "git::https://gitlab.com/org/terraform-azure-modules.git//networking/nsg?ref=v1.0.0"
  
  for_each = var.subnets
  
  name                = "nsg-${each.key}-${local.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  
  security_rules = lookup(each.value, "security_rules", [])
  
  tags = local.common_tags
}

# Associar NSG à Subnet
resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = var.subnets
  
  subnet_id                 = module.subnet[each.key].subnet_id
  network_security_group_id = module.nsg[each.key].nsg_id
}

# Outputs
output "resource_group_name" {
  description = "Nome do Resource Group criado"
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "ID da Virtual Network"
  value       = module.network.vnet_id
}

output "vnet_name" {
  description = "Nome da Virtual Network"
  value       = module.network.vnet_name
}

output "subnet_ids" {
  description = "IDs das Subnets criadas"
  value       = { for k, v in module.subnet : k => v.subnet_id }
}
