# Naming Convention Module
module "naming" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/foundation/naming?ref=v1.0.0"
  
  environment     = var.environment
  project_name    = var.project_name
  project_version = "01"
  location        = var.location
}

# Local Variables
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = module.naming.resource_group
  location = var.location
  tags     = local.common_tags
}

# Virtual Network with Subnets
module "vnet" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/vnet?ref=v1.0.0"
  
  name                = module.naming.virtual_network
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  
  subnets = {
    app = {
      address_prefixes = ["10.0.1.0/24"]
    }
    data = {
      address_prefixes = ["10.0.2.0/24"]
    }
  }
  
  tags = local.common_tags
}

# Network Security Group
module "nsg" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/nsg?ref=v1.0.0"
  
  name                = module.naming.network_security_group
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  
  security_rules = [
    {
      name                       = "allow-ssh"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
  
  tags = local.common_tags
}

# Storage Account
module "storage" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/storage/account?ref=v1.0.0"
  
  name                     = module.naming.storage_account
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  containers = {
    data = {
      access_type = "private"
    }
    logs = {
      access_type = "private"
    }
  }
  
  tags = local.common_tags
}

# Container Registry (Optional - uncomment if needed)
# module "acr" {
#   source = "git@github.com:org/terraform-azure-modules.git//modules/container/acr?ref=v1.0.0"
#   
#   name                = module.naming.container_registry
#   resource_group_name = azurerm_resource_group.main.name
#   location            = var.location
#   sku                 = "Basic"
#   
#   tags = local.common_tags
# }

# Virtual Machine (Optional - uncomment if needed)
# module "vm" {
#   source = "git@github.com:org/terraform-azure-modules.git//modules/compute/vm?ref=v1.0.0"
#   
#   name                = module.naming.virtual_machine
#   resource_group_name = azurerm_resource_group.main.name
#   location            = var.location
#   vm_size             = "Standard_B2s"
#   subnet_id           = module.vnet.subnet_ids["app"]
#   admin_ssh_key       = var.admin_ssh_key
#   
#   tags = local.common_tags
# }
