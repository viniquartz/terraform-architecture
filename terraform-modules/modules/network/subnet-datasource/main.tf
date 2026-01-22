terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

data "azurerm_subnet" "this" {
  name                 = var.name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.resource_group_name
}
