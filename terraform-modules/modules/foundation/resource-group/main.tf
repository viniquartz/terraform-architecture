terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

# Option 1: Create new Resource Group
resource "azurerm_resource_group" "this" {
  count = var.create ? 1 : 0

  name     = var.name
  location = var.location
  tags     = var.tags
}

# Option 2: Use existing Resource Group (data source)
data "azurerm_resource_group" "existing" {
  count = var.create ? 0 : 1

  name = var.name
}

# Outputs unified from both options
locals {
  resource_group_id       = var.create ? azurerm_resource_group.this[0].id : data.azurerm_resource_group.existing[0].id
  resource_group_name     = var.create ? azurerm_resource_group.this[0].name : data.azurerm_resource_group.existing[0].name
  resource_group_location = var.create ? azurerm_resource_group.this[0].location : data.azurerm_resource_group.existing[0].location
}
