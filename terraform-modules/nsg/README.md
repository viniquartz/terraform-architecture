# Azure Network Security Group Module

Terraform module to create an Azure Network Security Group (NSG) and optionally associate it with a subnet.

## Usage

```hcl
module "nsg" {
  source = "../../terraform-modules/nsg"

  nsg_name            = "my-nsg"
  location            = "West Europe"
  resource_group_name = "my-rg"
  subnet_id           = module.subnet.subnet_id

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
| nsg_name | Name of the network security group | `string` | yes | - |
| location | Azure region where the NSG will be created | `string` | yes | - |
| resource_group_name | Name of the resource group | `string` | yes | - |
| subnet_id | ID of the subnet to associate with the NSG (optional) | `string` | no | `null` |
| tags | Map of tags to apply to the NSG | `map(string)` | no | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| nsg_id | The ID of the network security group |
| nsg_name | The name of the network security group |

## Notes

- Use the `nsg-rules` module to add custom security rules to this NSG
- Subnet association is optional
