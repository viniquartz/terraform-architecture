# Azure NSG Custom Rules Module

Terraform module to add multiple custom security rules to an existing Network Security Group.

## Usage

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

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.0 |

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| resource_group_name | Name of the resource group where the NSG is located | `string` | yes | - |
| network_security_group_name | Name of the network security group | `string` | yes | - |
| security_rules | List of security rules to create | `list(object)` | yes | - |

### security_rules object structure

```hcl
{
  name                       = string  # Rule name
  priority                   = number  # 100-4096
  direction                  = string  # Inbound or Outbound
  access                     = string  # Allow or Deny
  protocol                   = string  # Tcp, Udp, Icmp, Esp, Ah, or *
  source_port_range          = string  # Port or range
  destination_port_range     = string  # Port or range
  source_address_prefix      = string  # IP, CIDR, or *
  destination_address_prefix = string  # IP, CIDR, or *
}
```

## Outputs

| Name | Description |
|------|-------------|
| rule_ids | Map of rule names to their IDs |
| rule_names | List of created rule names |

## Validation Rules

- Direction must be 'Inbound' or 'Outbound'
- Access must be 'Allow' or 'Deny'
- Protocol must be one of: Tcp, Udp, Icmp, Esp, Ah, or *
- Priority must be between 100 and 4096
