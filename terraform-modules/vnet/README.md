# Azure Virtual Network Module

Terraform module to create an Azure Virtual Network (VNET).

## Description

This module creates a Virtual Network in Azure with configurable address space and optional tagging. It includes validation for CIDR blocks and enforces the presence of the `Environment` tag when tags are provided.

## Usage

### Basic Example

```hcl
module "vnet" {
  source = "../../terraform-modules/vnet"

  vnet_name           = "my-vnet"
  location            = "West Europe"
  resource_group_name = "my-rg"
  address_space       = ["10.0.0.0/16"]

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### Multiple Address Spaces

```hcl
module "vnet" {
  source = "../../terraform-modules/vnet"

  vnet_name           = "my-vnet"
  location            = "West Europe"
  resource_group_name = "my-rg"
  address_space       = ["10.0.0.0/16", "10.1.0.0/16"]

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Examples

See [examples/basic](examples/basic) for a complete working example with resource group creation.

## Notes

- **VNET name** must be between 1 and 64 characters
- **Address spaces** are validated to ensure they are valid CIDR blocks
- **Environment tag** is required when any tags are provided
- Module supports multiple address spaces for complex network designs

## Validation Rules

| Rule | Description |
|------|-------------|
| VNET name length | Must be between 1 and 64 characters |
| CIDR blocks | All address spaces must be valid CIDR notation |
| Required tags | `Environment` tag is mandatory when tags are provided |

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
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_space"></a> [address\_space](#input\_address\_space) | Address space (CIDR blocks) for the virtual network | `list(string)` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region where the virtual network will be created | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where the virtual network will be created | `string` | n/a | yes |
| <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name) | Name of the virtual network | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to the virtual network | `map(string)` | `{}` | no |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_address_space"></a> [address\_space](#output\_address\_space) | Address space of the virtual network |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | Virtual network ID |
| <a name="output_vnet_name"></a> [vnet\_name](#output\_vnet\_name) | Virtual network name |
<!-- END_TF_DOCS -->
