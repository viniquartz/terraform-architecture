# Azure Subnet Module

Terraform module to create an Azure Subnet within a Virtual Network.

## Description

This module creates a subnet within an existing Azure Virtual Network. It supports configuring service endpoints for Azure services like Storage, SQL Database, Key Vault, and more.

## Usage

### Basic Example

```hcl
module "subnet" {
  source = "../../terraform-modules/subnet"

  subnet_name          = "my-subnet"
  resource_group_name  = "my-rg"
  virtual_network_name = "my-vnet"
  address_prefixes     = ["10.0.1.0/24"]
}
```

### With Service Endpoints

```hcl
module "subnet" {
  source = "../../terraform-modules/subnet"

  subnet_name          = "database-subnet"
  resource_group_name  = "my-rg"
  virtual_network_name = "my-vnet"
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.Sql"]
}
```

## Examples

See [examples/basic](examples/basic) for a complete working example.

## Notes

- **Subnet name** must be between 1 and 80 characters
- **Address prefixes** are validated to ensure they are valid CIDR blocks
- **Service endpoints** must start with `Microsoft.` prefix
- Common service endpoints: `Microsoft.Storage`, `Microsoft.Sql`, `Microsoft.KeyVault`, `Microsoft.ServiceBus`

## Validation Rules

| Rule | Description |
|------|-------------|
| Subnet name length | Must be between 1 and 80 characters |
| CIDR blocks | All address prefixes must be valid CIDR notation |
| Service endpoints | Must start with 'Microsoft.' prefix |

<!-- BEGIN_TF_DOCS -->


## Requirements

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.0 |

## Providers

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.0 |

## Resources

## Resources

| Name | Type |
|------|------|
| [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_prefixes"></a> [address\_prefixes](#input\_address\_prefixes) | Address prefixes (CIDR blocks) for the subnet | `list(string)` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where the subnet will be created | `string` | n/a | yes |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | Name of the subnet | `string` | n/a | yes |
| <a name="input_virtual_network_name"></a> [virtual\_network\_name](#input\_virtual\_network\_name) | Name of the virtual network where the subnet will be created | `string` | n/a | yes |
| <a name="input_service_endpoints"></a> [service\_endpoints](#input\_service\_endpoints) | List of service endpoints to associate with the subnet (e.g., Microsoft.Storage, Microsoft.Sql, Microsoft.KeyVault) | `list(string)` | `[]` | no |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_address_prefixes"></a> [address\_prefixes](#output\_address\_prefixes) | Address prefixes of the subnet |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | Subnet ID |
| <a name="output_subnet_name"></a> [subnet\_name](#output\_subnet\_name) | Subnet name |
<!-- END_TF_DOCS -->
