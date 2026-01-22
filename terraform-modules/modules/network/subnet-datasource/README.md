# Subnet Data Source Module

Terraform module to reference existing Subnets.

## Usage

```hcl
module "existing_subnet" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/subnet-datasource?ref=v1.0.0"
  
  name                 = "azr-prd-myapp01-weu-snet-app"
  virtual_network_name = "azr-prd-myapp01-weu-vnet"
  resource_group_name  = "azr-prd-myapp01-weu-rg"
}

# Use in VM deployment
module "vm" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/vm-linux?ref=v1.0.0"
  
  name                = "azr-prd-myapp01-weu-vm-web"
  resource_group_name = module.existing_subnet.resource_group_name
  location            = "westeurope"
  subnet_id           = module.existing_subnet.id
  
  admin_username = "azureuser"
  admin_ssh_key  = var.ssh_key
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| name | Subnet name | string | Yes |
| virtual_network_name | VNet name | string | Yes |
| resource_group_name | Resource Group name | string | Yes |

## Outputs

| Name | Description |
|------|-------------|
| id | Subnet ID |
| name | Subnet name |
| address_prefixes | Address prefixes list |
| virtual_network_name | VNet name |
