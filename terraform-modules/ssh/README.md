# Azure NSG SSH Rule Module

Terraform module to add an SSH security rule to an existing Network Security Group.

## Description

This module creates a single inbound security rule allowing SSH (port 22) traffic on an existing NSG. It's a convenience module for quickly enabling SSH access.

## Usage

### Basic SSH Rule (Allow from anywhere)

```hcl
module "ssh_rule" {
  source = "../../terraform-modules/ssh"

  rule_name                   = "allow-ssh"
  priority                    = 1001
  resource_group_name         = "my-rg"
  network_security_group_name = "my-nsg"
}
```

### SSH Rule with Restricted Source

```hcl
module "ssh_rule" {
  source = "../../terraform-modules/ssh"

  rule_name                   = "allow-ssh-from-office"
  priority                    = 1001
  source_address_prefix       = "203.0.113.0/24"
  resource_group_name         = "my-rg"
  network_security_group_name = "my-nsg"
}
```

## Examples

See [examples/basic](examples/basic) for a complete working example.

## Notes

- **Protocol**: TCP
- **Port**: 22 (SSH)
- **Direction**: Inbound
- **Action**: Allow
- **Default source**: `*` (any IP) - restrict this in production!
- For multiple custom rules, use the `nsg-rules` module instead

## Validation Rules

| Rule | Description |
|------|-------------|
| Priority | Must be between 100 and 4096 |
| Rule name | Must be between 1 and 80 characters |

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
| [azurerm_network_security_rule.ssh](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_network_security_group_name"></a> [network\_security\_group\_name](#input\_network\_security\_group\_name) | Network security group name | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group name | `string` | n/a | yes |
| <a name="input_priority"></a> [priority](#input\_priority) | Priority of the security rule | `number` | `1001` | no |
| <a name="input_rule_name"></a> [rule\_name](#input\_rule\_name) | Name of the SSH security rule | `string` | `"allow-ssh"` | no |
| <a name="input_source_address_prefix"></a> [source\_address\_prefix](#input\_source\_address\_prefix) | Source address prefix (CIDR or IP) | `string` | `"*"` | no |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_rule_id"></a> [rule\_id](#output\_rule\_id) | SSH security rule ID |
| <a name="output_rule_name"></a> [rule\_name](#output\_rule\_name) | SSH security rule name |
<!-- END_TF_DOCS -->
