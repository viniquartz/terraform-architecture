# Azure Subnet Module

Terraform module to create an Azure Subnet within a Virtual Network.

## Usage

```hcl
module "subnet" {
  source = "../../terraform-modules/subnet"

  subnet_name          = "my-subnet"
  resource_group_name  = "my-rg"
  virtual_network_name = "my-vnet"
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.Sql"]
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
| subnet_name | Name of the subnet | `string` | yes | - |
| resource_group_name | Name of the resource group | `string` | yes | - |
| virtual_network_name | Name of the virtual network | `string` | yes | - |
| address_prefixes | Address prefixes (CIDR blocks) for the subnet | `list(string)` | yes | - |
| service_endpoints | List of service endpoints (e.g., Microsoft.Storage, Microsoft.Sql) | `list(string)` | no | `[]` |

## Outputs

| Name | Description |
|------|-------------|
| subnet_id | The ID of the subnet |
| subnet_name | The name of the subnet |
| address_prefixes | The address prefixes of the subnet |

## Validation Rules

- Subnet name must be between 1 and 80 characters
- All address prefixes must be valid CIDR blocks
- Service endpoints must start with 'Microsoft.'
