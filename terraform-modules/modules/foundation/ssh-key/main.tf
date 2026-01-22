terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

resource "azurerm_ssh_public_key" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  public_key          = var.public_key

  tags = var.tags
}
