# Network Security Group Module

Terraform module to create and manage Azure Network Security Groups with dynamic security rules.

## Features

- Dynamic security rule creation from list
- Support for all rule types (Inbound/Outbound, Allow/Deny)
- Flexible source and destination configuration
- Priority auto-management
- Service tags support

## Usage

### Basic Example (POC)

```hcl
module "nsg" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/nsg?ref=v1.0.0"
  
  name                = module.naming.network_security_group
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  
  security_rules = [
    {
      name                       = "allow-ssh"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
  
  tags = local.common_tags
}
```

### Web Application NSG

```hcl
module "nsg_web" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/nsg?ref=v1.0.0"
  
  name                = "${module.naming.network_security_group}-web"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  
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
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "deny-all-inbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
  
  tags = local.common_tags
}
```

### Database NSG (Production Security)

```hcl
module "nsg_database" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/nsg?ref=v1.0.0"
  
  name                = "${module.naming.network_security_group}-db"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  
  security_rules = [
    {
      name                       = "allow-sql-from-app"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      source_address_prefix      = "10.0.1.0/24"  # App subnet
      destination_address_prefix = "*"
    },
    {
      name                       = "deny-all-inbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
  
  tags = local.common_tags
}
```

### Using Service Tags

```hcl
module "nsg" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/nsg?ref=v1.0.0"
  
  name                = module.naming.network_security_group
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  
  security_rules = [
    {
      name                       = "allow-azure-loadbalancer"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow-storage"
      priority                   = 110
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "Storage"
    }
  ]
  
  tags = local.common_tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Network Security Group name | string | - | yes |
| resource_group_name | Resource Group name | string | - | yes |
| location | Azure region | string | - | yes |
| security_rules | List of security rules | list(object) | [] | no |
| tags | Tags to apply to resources | map(string) | {} | no |

### Security Rule Object Structure

```hcl
security_rules = [
  {
    name                       = "rule-name"
    priority                   = 100
    direction                  = "Inbound"  # or "Outbound"
    access                     = "Allow"    # or "Deny"
    protocol                   = "Tcp"      # or "Udp", "Icmp", "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
]
```

## Outputs

| Name | Description |
|------|-------------|
| id | Network Security Group ID |
| name | Network Security Group name |

## Associate NSG with Subnet

```hcl
# Create VNet and NSG
module "vnet" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/vnet?ref=v1.0.0"
  # ...
}

module "nsg" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/nsg?ref=v1.0.0"
  # ...
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = module.vnet.subnet_ids["app"]
  network_security_group_id = module.nsg.id
}
```

## Associate NSG with NIC

```hcl
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = module.nsg.id
}
```

## Common Security Rules

### Allow SSH (Port 22)

```hcl
{
  name                       = "allow-ssh"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "YOUR_IP/32"  # Restrict to your IP
  destination_address_prefix = "*"
}
```

### Allow RDP (Port 3389)

```hcl
{
  name                       = "allow-rdp"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "3389"
  source_address_prefix      = "YOUR_IP/32"
  destination_address_prefix = "*"
}
```

### Allow HTTP/HTTPS

```hcl
{
  name                       = "allow-web"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80,443"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}
```

### Deny All (Explicit)

```hcl
{
  name                       = "deny-all-inbound"
  priority                   = 4096
  direction                  = "Inbound"
  access                     = "Deny"
  protocol                   = "*"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}
```

## Service Tags

Common service tags:
- `Internet` - Public internet
- `VirtualNetwork` - VNet address space
- `AzureLoadBalancer` - Azure Load Balancer
- `Storage` - Azure Storage
- `Sql` - Azure SQL Database
- `AzureKeyVault` - Azure Key Vault
- `AzureContainerRegistry` - Azure Container Registry

## Priority Guidelines

- 100-999: High priority (critical access)
- 1000-2999: Medium priority (standard access)
- 3000-4095: Low priority (deny rules, logging)
- 4096: Lowest priority (catch-all deny)

## Security Best Practices

### For POC/Development
- Allow broad access for testing
- Use source IP `*` for convenience
- Simple rules for rapid development

### For Production
- Restrict source IPs to known ranges
- Use service tags instead of `*`
- Implement explicit deny rules
- Follow principle of least privilege
- Document all rules with clear names

Example production pattern:

```hcl
security_rules = [
  # 1. Allow required traffic (specific)
  {
    name                       = "allow-app-to-db"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "10.0.2.0/24"
  },
  # 2. Allow Azure services
  {
    name                       = "allow-azure-lb"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  },
  # 3. Explicit deny everything else
  {
    name                       = "deny-all-other"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
]
```

## Notes

- NSG rules are stateful (return traffic automatically allowed)
- Default NSG allows VNet traffic and Azure Load Balancer
- Default NSG denies all other inbound, allows all outbound
- Priority must be between 100-4096 (unique per NSG)
- Lower priority number = higher precedence

## Common Issues

### Issue: Rule not working

**Symptom:** Traffic blocked despite allow rule

**Solution:**
1. Check rule priority (lower = higher precedence)
2. Verify direction (Inbound vs Outbound)
3. Check for higher priority deny rule
4. Verify source/destination address prefixes

### Issue: Priority conflict

**Error:** `Priority already exists`

**Solution:** Use unique priority values for each rule

### Issue: Port range invalid

**Error:** `Invalid port range format`

**Solution:** Use single port (443), range (80-443), or comma-separated (80,443)

## Migration from Old Structure

Old path: `modules/nsg`
New path: `modules/network/nsg`

Update your module sources:

```hcl
# Old
module "nsg" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/nsg?ref=v1.0.0"
}

# New
module "nsg" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/nsg?ref=v2.0.0"
}
```
