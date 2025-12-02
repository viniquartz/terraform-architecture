# Azure Network Security Group Module

Terraform module to create an Azure Network Security Group (NSG) and optionally associate it with a subnet.

## Description

This module creates a Network Security Group in Azure. NSGs contain security rules that allow or deny network traffic to resources. You can optionally associate the NSG with a subnet.

## Usage

### Basic NSG

```hcl
module "nsg" {
  source = "../../terraform-modules/nsg"

  nsg_name            = "my-nsg"
  location            = "West Europe"
  resource_group_name = "my-rg"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### NSG with Subnet Association

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

## Examples

See [examples/basic](examples/basic) for a complete working example.

## Notes

- **NSG** is created empty by default - use `ssh` or `nsg-rules` modules to add security rules
- **Subnet association** is optional - can be added later
- **Tags** are optional but recommended for resource organization
- Use the `nsg-rules` module for multiple custom security rules
- Use the `ssh` module for a quick SSH-only rule

## Validation Rules

| Rule | Description |
|------|-------------|
| NSG name length | Must be between 1 and 80 characters |

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
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_subnet_network_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | Azure region | `string` | n/a | yes |
| <a name="input_nsg_name"></a> [nsg\_name](#input\_nsg\_name) | Name of the network security group | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group name | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID to associate with NSG | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nsg_id"></a> [nsg\_id](#output\_nsg\_id) | Network security group ID |
| <a name="output_nsg_name"></a> [nsg\_name](#output\_nsg\_name) | Network security group name |
<!-- END_TF_DOCS -->
