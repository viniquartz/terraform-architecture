# Virtual Network Module

Terraform module to create and manage Azure Virtual Networks with dynamic subnet creation.

## Features

- Dynamic subnet creation from map
- Service endpoints configuration
- DNS servers configuration
- Multiple address spaces support
- Full customization per subnet

## Usage

### Basic Example (POC)

```hcl
module "vnet" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/vnet?ref=v1.0.0"
  
  name                = module.naming.virtual_network
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  
  subnets = {
    app = {
      address_prefixes = ["10.0.1.0/24"]
    }
    data = {
      address_prefixes = ["10.0.2.0/24"]
    }
  }
  
  tags = local.common_tags
}
```

### With Service Endpoints

```hcl
module "vnet" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/vnet?ref=v1.0.0"
  
  name                = module.naming.virtual_network
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  
  subnets = {
    app = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    data = {
      address_prefixes  = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    }
    private = {
      address_prefixes = ["10.0.3.0/24"]
    }
  }
  
  tags = local.common_tags
}
```

### With Custom DNS Servers

```hcl
module "vnet" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/vnet?ref=v1.0.0"
  
  name                = module.naming.virtual_network
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]
  
  subnets = {
    dns = {
      address_prefixes = ["10.0.0.0/28"]
    }
    app = {
      address_prefixes = ["10.0.1.0/24"]
    }
  }
  
  tags = local.common_tags
}
```

### Multiple Address Spaces

```hcl
module "vnet" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/vnet?ref=v1.0.0"
  
  name                = module.naming.virtual_network
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  address_space       = ["10.0.0.0/16", "172.16.0.0/16"]
  
  subnets = {
    app1 = {
      address_prefixes = ["10.0.1.0/24"]
    }
    app2 = {
      address_prefixes = ["172.16.1.0/24"]
    }
  }
  
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
| name | Virtual Network name | string | - | yes |
| resource_group_name | Resource Group name | string | - | yes |
| location | Azure region | string | - | yes |
| address_space | List of address spaces | list(string) | - | yes |
| dns_servers | List of DNS servers | list(string) | [] | no |
| subnets | Map of subnets to create | map(object) | {} | no |
| tags | Tags to apply to resources | map(string) | {} | no |

### Subnet Object Structure

```hcl
subnets = {
  "subnet-name" = {
    address_prefixes  = ["10.0.1.0/24"]  # Required
    service_endpoints = []                # Optional
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| id | Virtual Network ID |
| name | Virtual Network name |
| address_space | Virtual Network address space |
| subnet_ids | Map of subnet names to IDs |
| subnet_names | Map of subnet keys to full names |

## Usage with Other Modules

### With NSG

```hcl
module "vnet" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/vnet?ref=v1.0.0"
  
  name                = module.naming.virtual_network
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  
  subnets = {
    app = {
      address_prefixes = ["10.0.1.0/24"]
    }
  }
  
  tags = local.common_tags
}

module "nsg" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/nsg?ref=v1.0.0"
  
  name                = module.naming.network_security_group
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  
  security_rules = [
    {
      name                       = "allow-https"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
  
  tags = local.common_tags
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = module.vnet.subnet_ids["app"]
  network_security_group_id = module.nsg.id
}
```

### With VM

```hcl
module "vnet" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/vnet?ref=v1.0.0"
  
  name                = module.naming.virtual_network
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  
  subnets = {
    app = {
      address_prefixes = ["10.0.1.0/24"]
    }
  }
  
  tags = local.common_tags
}

module "vm" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/vm?ref=v1.0.0"
  
  name                = module.naming.virtual_machine
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  vm_size             = "Standard_B2s"
  subnet_id           = module.vnet.subnet_ids["app"]
  admin_ssh_key       = var.admin_ssh_key
  
  tags = local.common_tags
}
```

## Network Design Best Practices

### Address Space Planning

- Use private IP ranges: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
- Plan for growth: Start with /16 for VNet, use /24 for subnets
- Reserve address space for future expansion
- Document IP allocation scheme

### Subnet Sizing

| Purpose | Recommended Size | IP Count |
|---------|------------------|----------|
| Small app tier | /26 | 64 |
| Medium app tier | /24 | 256 |
| Large app tier | /22 | 1024 |
| Database tier | /27 | 32 |
| Gateway subnet | /27 | 32 |
| Azure Bastion | /26 | 64 |

### Service Endpoints

Enable service endpoints for:
- Microsoft.Storage (Storage Accounts)
- Microsoft.Sql (SQL Database)
- Microsoft.KeyVault (Key Vault)
- Microsoft.ContainerRegistry (ACR)

Benefits:
- Improved security (traffic stays on Azure backbone)
- Better performance
- No public IP needed for Azure services

## Notes

- VNet name must be 2-64 characters (alphanumeric, underscore, hyphen, period)
- Subnet names must be unique within VNet
- Azure reserves 5 IP addresses per subnet (.0, .1, .2, .3, .255)
- Service endpoints are free (no additional cost)
- DNS servers are applied to entire VNet (all subnets)

## Common Issues

### Issue: Subnet too small

**Error:** `The subnet 'subnet-name' does not have enough capacity`

**Solution:** Increase subnet size or reduce number of resources

### Issue: Overlapping address space

**Error:** `Subnet address prefix overlaps with existing subnet`

**Solution:** Check address space allocation and avoid overlaps

### Issue: Service endpoint not working

**Symptom:** Cannot access Azure service from subnet

**Solution:**
1. Verify service endpoint is configured on subnet
2. Check Azure service firewall rules allow subnet
3. Verify NSG rules allow outbound traffic

## Migration from Old Structure

Old path: `modules/vnet`
New path: `modules/network/vnet`

Update your module sources:

```hcl
# Old
module "vnet" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/vnet?ref=v1.0.0"
}

# New
module "vnet" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/vnet?ref=v2.0.0"
}
```
