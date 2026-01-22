# Resource Group Module

Flexible module to create a new Resource Group or use an existing one via data source.

## Features

- Create new Resource Group or use existing
- Unified outputs regardless of creation method
- Tags support for new resource groups

## Usage

### Create New Resource Group

```hcl
module "rg" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/foundation/resource-group?ref=v1.0.0"
  
  name     = module.naming.resource_group
  location = "westeurope"
  create   = true
  
  tags = {
    Environment = "prd"
    Project     = "myapp"
  }
}
```

### Use Existing Resource Group

```hcl
module "rg_existing" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/foundation/resource-group?ref=v1.0.0"
  
  name   = "azr-prd-myapp01-weu-rg"
  create = false
}

# Access outputs the same way
resource "azurerm_virtual_network" "example" {
  name                = "vnet-example"
  resource_group_name = module.rg_existing.name
  location            = module.rg_existing.location
  address_space       = ["10.0.0.0/16"]
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| name | Resource Group name | string | Yes | - |
| location | Azure region (only for new RG) | string | No | null |
| create | Create new (true) or use existing (false) | bool | No | true |
| tags | Tags (only for new RG) | map(string) | No | {} |

## Outputs

| Name | Description |
|------|-------------|
| id | Resource Group ID |
| name | Resource Group name |
| location | Resource Group location |

## Examples

### Conditional Creation Based on Environment

```hcl
locals {
  use_existing_rg = var.environment == "prd"
}

module "rg" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/foundation/resource-group?ref=v1.0.0"
  
  name     = "azr-${var.environment}-myapp01-weu-rg"
  location = "westeurope"
  create   = !local.use_existing_rg
  
  tags = local.common_tags
}
```
