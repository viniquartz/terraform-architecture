terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

data "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
}
