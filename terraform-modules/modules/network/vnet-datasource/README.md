# Virtual Network Data Source Module

Terraform module to reference existing Virtual Networks.

## Usage

```hcl
module "existing_vnet" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/vnet-datasource?ref=v1.0.0"
  
  name                = "azr-prd-myapp01-weu-vnet"
  resource_group_name = "azr-prd-myapp01-weu-rg"
}

# Use in other resources
resource "azurerm_subnet" "new_subnet" {
  name                 = "snet-new"
  resource_group_name  = module.existing_vnet.name
  virtual_network_name = module.existing_vnet.name
  address_prefixes     = ["10.0.99.0/24"]
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| name | VNet name | string | Yes |
| resource_group_name | Resource Group name | string | Yes |

## Outputs

| Name | Description |
|------|-------------|
| id | VNet ID |
| name | VNet name |
| address_space | Address space |
| subnets | Subnet names list |
| location | Azure region |
