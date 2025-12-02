# Azure Virtual Network Module

Terraform module to create an Azure Virtual Network (VNET).

## Usage

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

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.0 |

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| vnet_name | Name of the virtual network | `string` | yes | - |
| location | Azure region where the virtual network will be created | `string` | yes | - |
| resource_group_name | Name of the resource group where the virtual network will be created | `string` | yes | - |
| address_space | Address space (CIDR blocks) for the virtual network | `list(string)` | yes | - |
| tags | Map of tags to apply to the virtual network | `map(string)` | no | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | The ID of the virtual network |
| vnet_name | The name of the virtual network |
| address_space | The address space of the virtual network |

## Validation Rules

- VNET name must be between 1 and 64 characters
- All address spaces must be valid CIDR blocks
- Tags must include 'Environment' key when tags are provided

## Example

See [examples/basic](examples/basic) for a complete example.
