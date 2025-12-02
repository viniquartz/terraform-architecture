# Azure NSG SSH Rule Module

Terraform module to add an SSH security rule to an existing Network Security Group.

## Usage

```hcl
module "ssh_rule" {
  source = "../../terraform-modules/ssh"

  rule_name                   = "allow-ssh"
  priority                    = 1001
  source_address_prefix       = "10.0.0.0/8"
  resource_group_name         = "my-rg"
  network_security_group_name = "my-nsg"
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
| rule_name | Name of the security rule | `string` | yes | - |
| resource_group_name | Name of the resource group | `string` | yes | - |
| network_security_group_name | Name of the NSG to add the rule to | `string` | yes | - |
| priority | Priority of the rule (100-4096) | `number` | no | `1001` |
| source_address_prefix | Source IP address or CIDR | `string` | no | `"*"` |

## Outputs

| Name | Description |
|------|-------------|
| rule_id | The ID of the security rule |
| rule_name | The name of the security rule |

## Notes

- Rule allows inbound TCP traffic on port 22
- For multiple custom rules, use the `nsg-rules` module instead
