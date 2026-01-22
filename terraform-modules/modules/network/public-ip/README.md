# Public IP Module

Terraform module to create and manage Azure Public IP addresses.

## Features

- Static or Dynamic allocation
- Basic or Standard SKU
- Availability zone support
- Custom DNS domain label
- Configurable idle timeout

## Usage

### Basic Static IP

```hcl
module "public_ip" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/public-ip?ref=v1.0.0"
  
  name                = "${module.naming.public_ip}-lb"
  resource_group_name = module.rg.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  
  tags = local.common_tags
}
```

### With DNS Label

```hcl
module "public_ip_web" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/public-ip?ref=v1.0.0"
  
  name                = "${module.naming.public_ip}-web"
  resource_group_name = module.rg.name
  location            = "westeurope"
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "myapp-web-${var.environment}"
  
  tags = local.common_tags
}

# FQDN will be: myapp-web-prd.westeurope.cloudapp.azure.com
```

### With Availability Zones

```hcl
module "public_ip_zone" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/public-ip?ref=v1.0.0"
  
  name                = "${module.naming.public_ip}-zone"
  resource_group_name = module.rg.name
  location            = "westeurope"
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  
  tags = local.common_tags
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| name | Public IP name | string | Yes | - |
| resource_group_name | Resource Group name | string | Yes | - |
| location | Azure region | string | Yes | - |
| allocation_method | Static or Dynamic | string | No | Static |
| sku | Basic or Standard | string | No | Standard |
| zones | Availability zones | list(string) | No | [] |
| domain_name_label | DNS label | string | No | null |
| idle_timeout_in_minutes | Timeout (4-30) | number | No | 4 |
| tags | Tags to apply | map(string) | No | {} |

## Outputs

| Name | Description |
|------|-------------|
| id | Public IP ID |
| name | Public IP name |
| ip_address | IP address value |
| fqdn | Fully qualified domain name |

## SKU Comparison

| Feature | Basic | Standard |
|---------|-------|----------|
| Allocation | Dynamic/Static | Static only |
| Availability Zones | No | Yes |
| Security | Open by default | Closed by default |
| Price | Lower | Higher |

**Recommendation:** Use Standard SKU for production workloads.

## Examples

### Multiple IPs with Count

```hcl
module "public_ips" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/public-ip?ref=v1.0.0"
  count  = 3
  
  name                = "${module.naming.public_ip}-${format("%02d", count.index + 1)}"
  resource_group_name = module.rg.name
  location            = "westeurope"
  
  tags = local.common_tags
}
```
