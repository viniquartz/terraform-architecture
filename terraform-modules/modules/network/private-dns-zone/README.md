# Private DNS Zone Module

Terraform module to create and manage Azure Private DNS Zones with Virtual Network links.

## Features

- Private DNS resolution for Azure resources
- Multiple VNet link support
- Auto-registration option
- Built-in Azure Private Link zones

## Usage

### Basic Private DNS Zone

```hcl
module "private_dns_zone" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/private-dns-zone?ref=v1.0.0"
  
  name                = "myapp.local"
  resource_group_name = module.rg.name
  
  virtual_network_links = {
    vnet1 = {
      virtual_network_id   = module.vnet.id
      registration_enabled = true
    }
  }
  
  tags = local.common_tags
}
```

### For Azure SQL Private Endpoint

```hcl
module "private_dns_sql" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/private-dns-zone?ref=v1.0.0"
  
  name                = "privatelink.database.windows.net"
  resource_group_name = module.rg.name
  
  virtual_network_links = {
    app_vnet = {
      virtual_network_id   = module.vnet_app.id
      registration_enabled = false
    }
  }
  
  tags = local.common_tags
}
```

### Multiple VNet Links

```hcl
module "private_dns_zone" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/private-dns-zone?ref=v1.0.0"
  
  name                = "mycompany.local"
  resource_group_name = module.rg.name
  
  virtual_network_links = {
    prod_vnet = {
      virtual_network_id   = module.vnet_prod.id
      registration_enabled = true
    }
    dr_vnet = {
      virtual_network_id   = module.vnet_dr.id
      registration_enabled = true
    }
    hub_vnet = {
      virtual_network_id   = module.vnet_hub.id
      registration_enabled = false
    }
  }
  
  tags = local.common_tags
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| name | Private DNS Zone name | string | Yes | - |
| resource_group_name | Resource Group name | string | Yes | - |
| virtual_network_links | Map of VNet links | map(object) | No | {} |
| tags | Tags to apply | map(string) | No | {} |

## Outputs

| Name | Description |
|------|-------------|
| id | Private DNS Zone ID |
| name | Private DNS Zone name |
| vnet_link_ids | VNet link IDs map |

## Azure Private Link DNS Zones

Common Private Link zones:

| Service | Private DNS Zone |
|---------|-----------------|
| SQL Database | privatelink.database.windows.net |
| Blob Storage | privatelink.blob.core.windows.net |
| Key Vault | privatelink.vaultcore.azure.net |
| ACR | privatelink.azurecr.io |
| AKS | privatelink.westeurope.azmk8s.io |
| App Service | privatelink.azurewebsites.net |

## Auto-registration

When `registration_enabled = true`, VMs in the linked VNet automatically register their DNS records in the private zone.

**Use cases:**

- Enable for application VNets
- Disable for hub/transit VNets
- Disable for Private Endpoint zones
