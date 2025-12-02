# Azure NSG Custom Rules Module

Terraform module to add multiple custom security rules to an existing Network Security Group.

## Description

This module allows you to create multiple security rules on an existing NSG using a single module call. It's ideal for managing complex security configurations with multiple allow/deny rules.

## Usage

### Web Server Rules (HTTP + HTTPS)

```hcl
module "nsg_rules" {
  source = "../../terraform-modules/nsg-rules"

  resource_group_name         = "my-rg"
  network_security_group_name = "my-nsg"

  security_rules = [
    {
      name                       = "allow-http"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-https"
      priority                   = 101
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
}
```

### Database Rules (Restricted Access)

```hcl
module "nsg_rules" {
  source = "../../terraform-modules/nsg-rules"

  resource_group_name         = "my-rg"
  network_security_group_name = "my-nsg"

  security_rules = [
    {
      name                       = "allow-postgresql"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "5432"
      source_address_prefix      = "10.0.0.0/16"
      destination_address_prefix = "*"
    }
  ]
}
```

## Examples

See [examples/basic](examples/basic) for a complete working example.

## Notes

- **Multiple rules** can be created with a single module call
- **Priority** must be unique within the NSG (100-4096)
- **Direction** can be Inbound or Outbound
- **Protocol** supports Tcp, Udp, Icmp, Esp, Ah, or * (any)
- Each rule is validated before creation

## Security Rule Object Structure

```hcl
{
  name                       = string  # Rule name (1-80 characters)
  priority                   = number  # 100-4096 (must be unique)
  direction                  = string  # "Inbound" or "Outbound"
  access                     = string  # "Allow" or "Deny"
  protocol                   = string  # "Tcp", "Udp", "Icmp", "Esp", "Ah", or "*"
  source_port_range          = string  # Port number, range, or "*"
  destination_port_range     = string  # Port number, range, or "*"
  source_address_prefix      = string  # IP, CIDR, or "*"
  destination_address_prefix = string  # IP, CIDR, or "*"
}
```

## Validation Rules

| Rule | Description |
|------|-------------|
| Direction | Must be 'Inbound' or 'Outbound' |
| Access | Must be 'Allow' or 'Deny' |
| Protocol | Must be Tcp, Udp, Icmp, Esp, Ah, or * |
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
| [azurerm_network_security_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_network_security_group_name"></a> [network\_security\_group\_name](#input\_network\_security\_group\_name) | Name of the network security group to add rules to | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where the NSG is located | `string` | n/a | yes |
| <a name="input_security_rules"></a> [security\_rules](#input\_security\_rules) | List of security rules to create | <pre>list(object({<br/>    name                       = string<br/>    priority                   = number<br/>    direction                  = string<br/>    access                     = string<br/>    protocol                   = string<br/>    source_port_range          = string<br/>    destination_port_range     = string<br/>    source_address_prefix      = string<br/>    destination_address_prefix = string<br/>  }))</pre> | n/a | yes |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_rule_ids"></a> [rule\_ids](#output\_rule\_ids) | Map of rule names to their IDs |
| <a name="output_rule_names"></a> [rule\_names](#output\_rule\_names) | List of created rule names |
<!-- END_TF_DOCS -->
