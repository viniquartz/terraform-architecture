# DNS Zone Module

Terraform module to create and manage Azure DNS Zones with DNS records.

## Features

- Public DNS zone management
- A records support
- CNAME records support
- Returns name servers for domain delegation

## Usage

### Basic DNS Zone

```hcl
module "dns_zone" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/dns-zone?ref=v1.0.0"
  
  name                = "example.com"
  resource_group_name = module.rg.name
  
  tags = local.common_tags
}
```

### With DNS Records

```hcl
module "dns_zone" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/dns-zone?ref=v1.0.0"
  
  name                = "example.com"
  resource_group_name = module.rg.name
  
  a_records = {
    www = {
      ttl     = 300
      records = ["203.0.113.10"]
    }
    api = {
      ttl     = 300
      records = ["203.0.113.20"]
    }
  }
  
  cname_records = {
    blog = {
      ttl    = 300
      record = "myblog.azurewebsites.net"
    }
  }
  
  tags = local.common_tags
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| name | DNS Zone name | string | Yes | - |
| resource_group_name | Resource Group name | string | Yes | - |
| a_records | Map of A records | map(object) | No | {} |
| cname_records | Map of CNAME records | map(object) | No | {} |
| tags | Tags to apply | map(string) | No | {} |

## Outputs

| Name | Description |
|------|-------------|
| id | DNS Zone ID |
| name | DNS Zone name |
| name_servers | Name servers for delegation |

## Domain Delegation

After creating the DNS zone, update your domain registrar with the name servers:

```bash
terraform output -module=dns_zone name_servers
```

Configure these name servers in your domain registrar (GoDaddy, Namecheap, etc.).

## Examples

### Complete Web Application DNS

```hcl
module "dns_zone_myapp" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/dns-zone?ref=v1.0.0"
  
  name                = "myapp.com"
  resource_group_name = module.rg.name
  
  a_records = {
    "@" = {
      ttl     = 300
      records = [module.public_ip_web.ip_address]
    }
    www = {
      ttl     = 300
      records = [module.public_ip_web.ip_address]
    }
  }
  
  cname_records = {
    api   = { ttl = 300, record = "myapp-api.azurewebsites.net" }
    admin = { ttl = 300, record = "myapp-admin.azurewebsites.net" }
  }
  
  tags = local.common_tags
}
```
