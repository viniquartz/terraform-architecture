# Private Endpoint Module

Terraform module to create Private Endpoints for Azure services.

## Features

- Secure private connectivity to Azure services
- Automatic DNS integration
- Support for all Azure services with Private Link
- Manual or automatic approval
- Network interface in your VNet

## Usage

### SQL Database Private Endpoint

```hcl
module "private_endpoint_sql" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/security/private-endpoint?ref=v1.0.0"
  
  name                           = "${module.naming.base_name}-pe-sql"
  resource_group_name            = module.rg.name
  location                       = var.location
  subnet_id                      = module.subnet_private.id
  private_connection_resource_id = module.sql_server.id
  subresource_names              = ["sqlServer"]
  
  private_dns_zone_ids = [module.private_dns_sql.id]
  
  tags = local.common_tags
}
```

### Key Vault Private Endpoint

```hcl
module "private_endpoint_kv" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/security/private-endpoint?ref=v1.0.0"
  
  name                           = "${module.naming.base_name}-pe-kv"
  resource_group_name            = module.rg.name
  location                       = "westeurope"
  subnet_id                      = module.subnet_private.id
  private_connection_resource_id = module.key_vault.id
  subresource_names              = ["vault"]
  
  private_dns_zone_ids = [module.private_dns_kv.id]
  
  tags = local.common_tags
}
```

### Storage Account Private Endpoint (Blob)

```hcl
module "private_endpoint_blob" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/security/private-endpoint?ref=v1.0.0"
  
  name                           = "${module.naming.base_name}-pe-blob"
  resource_group_name            = module.rg.name
  location                       = "westeurope"
  subnet_id                      = module.subnet_private.id
  private_connection_resource_id = module.storage.id
  subresource_names              = ["blob"]
  
  private_dns_zone_ids = [
    module.private_dns_blob.id
  ]
  
  tags = local.common_tags
}
```

### With Manual Approval

```hcl
module "private_endpoint_manual" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/security/private-endpoint?ref=v1.0.0"
  
  name                           = "${module.naming.base_name}-pe-manual"
  resource_group_name            = module.rg.name
  location                       = "westeurope"
  subnet_id                      = module.subnet_private.id
  private_connection_resource_id = var.external_resource_id
  subresource_names              = ["sqlServer"]
  is_manual_connection           = true
  request_message                = "Please approve connection from ${var.project_name}"
  
  tags = local.common_tags
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| name | Private Endpoint name | string | Yes | - |
| resource_group_name | Resource Group name | string | Yes | - |
| location | Azure region | string | Yes | - |
| subnet_id | Subnet ID | string | Yes | - |
| private_connection_resource_id | Target resource ID | string | Yes | - |
| subresource_names | Subresource names list | list(string) | Yes | - |
| is_manual_connection | Require approval | bool | No | false |
| request_message | Approval message | string | No | null |
| private_dns_zone_ids | DNS Zone IDs | list(string) | No | null |
| tags | Tags to apply | map(string) | No | {} |

## Outputs

| Name | Description |
|------|-------------|
| id | Private Endpoint ID |
| name | Private Endpoint name |
| private_ip_address | Private IP address |
| network_interface_id | Network Interface ID |

## Subresource Names by Service

| Service | Subresource Name |
|---------|-----------------|
| SQL Database | sqlServer |
| Storage Account (Blob) | blob |
| Storage Account (File) | file |
| Storage Account (Queue) | queue |
| Storage Account (Table) | table |
| Key Vault | vault |
| Cosmos DB (SQL) | Sql |
| Cosmos DB (MongoDB) | MongoDB |
| Azure Container Registry | registry |
| App Service | sites |
| Azure Kubernetes Service | management |
| Event Hub | namespace |
| Service Bus | namespace |

## Complete Example with DNS

```hcl
# Private DNS Zone
module "private_dns_sql" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/private-dns-zone?ref=v1.0.0"
  
  name                = "privatelink.database.windows.net"
  resource_group_name = module.rg.name
  
  virtual_network_links = {
    vnet = {
      virtual_network_id   = module.vnet.id
      registration_enabled = false
    }
  }
}

# Private Endpoint
module "private_endpoint_sql" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/security/private-endpoint?ref=v1.0.0"
  
  name                           = "${module.naming.base_name}-pe-sql"
  resource_group_name            = module.rg.name
  location                       = "westeurope"
  subnet_id                      = module.subnet_private.id
  private_connection_resource_id = module.sql_server.id
  subresource_names              = ["sqlServer"]
  private_dns_zone_ids           = [module.private_dns_sql.id]
  
  tags = local.common_tags
}
```

## Subnet Requirements

The subnet must have:

- `private_endpoint_network_policies_enabled = false`
- Sufficient IP addresses available
- Network security rules allowing traffic

```hcl
module "subnet_private" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/subnet?ref=v1.0.0"
  
  name                 = "${module.naming.subnet}-private"
  resource_group_name  = module.rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.10.0/24"]
  
  private_endpoint_network_policies_enabled = false
}
```
