# SQL Server Module

Terraform module to create Azure SQL Server (Logical Server).

## Features

- SQL authentication or Azure AD only
- Firewall rules and VNet rules
- System or User Assigned Managed Identity
- TDE with customer-managed keys
- Private endpoint support
- Minimum TLS 1.2

## Usage

### Basic SQL Server

```hcl
module "sql_server" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/database/sql-server?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-sql"
  resource_group_name = module.rg.name
  location            = var.location
  version             = "12.0"
  
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
  
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  
  tags = local.common_tags
}
```

### With Firewall Rules

```hcl
module "sql_server" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/database/sql-server?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-sql"
  resource_group_name = module.rg.name
  location            = "westeurope"
  
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
  
  public_network_access_enabled = true
  
  firewall_rules = {
    office = {
      start_ip = "203.0.113.0"
      end_ip   = "203.0.113.255"
    }
    azure_services = {
      start_ip = "0.0.0.0"
      end_ip   = "0.0.0.0"
    }
  }
  
  tags = local.common_tags
}
```

### With VNet Integration

```hcl
module "sql_server" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/database/sql-server?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-sql"
  resource_group_name = module.rg.name
  location            = "westeurope"
  
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
  
  public_network_access_enabled = false
  
  vnet_rules = {
    app_subnet = {
      subnet_id = module.subnet_app.id
    }
  }
  
  tags = local.common_tags
}
```

### Azure AD Authentication Only

```hcl
module "sql_server" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/database/sql-server?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-sql"
  resource_group_name = module.rg.name
  location            = "westeurope"
  
  azuread_administrator = {
    login_username              = "sql-admins"
    object_id                   = var.aad_admin_group_id
    azuread_authentication_only = true
  }
  
  identity_type = "SystemAssigned"
  
  tags = local.common_tags
}
```

### With Managed Identity and Customer-Managed Key

```hcl
module "sql_server" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/database/sql-server?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-sql"
  resource_group_name = module.rg.name
  location            = "westeurope"
  
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
  
  identity_type = "SystemAssigned"
  
  transparent_data_encryption_key_vault_key_id = module.key_vault_key.id
  
  azuread_administrator = {
    login_username = "sql-admins"
    object_id      = var.aad_admin_group_id
  }
  
  tags = local.common_tags
}
```

### With Private Endpoint

```hcl
module "sql_server" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/database/sql-server?ref=v1.0.0"
  
  name                          = "${module.naming.base_name}-sql"
  resource_group_name           = module.rg.name
  location                      = "westeurope"
  administrator_login           = "sqladmin"
  administrator_login_password  = var.sql_admin_password
  public_network_access_enabled = false
  
  tags = local.common_tags
}

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

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| name | SQL Server name | string | Yes | - |
| resource_group_name | Resource Group | string | Yes | - |
| location | Azure region | string | Yes | - |
| version | SQL version | string | No | 12.0 |
| administrator_login | Admin username | string | No | null |
| administrator_login_password | Admin password | string | No | null |
| minimum_tls_version | Minimum TLS | string | No | 1.2 |
| public_network_access_enabled | Public access | bool | No | false |
| azuread_administrator | AAD admin | object | No | null |
| identity_type | Identity type | string | No | null |
| firewall_rules | Firewall rules | map | No | {} |
| vnet_rules | VNet rules | map | No | {} |
| tags | Tags | map(string) | No | {} |

## Outputs

| Name | Description |
|------|-------------|
| id | SQL Server ID |
| name | SQL Server name |
| fqdn | Fully qualified domain name |
| identity_principal_id | Managed Identity Principal ID |

## Firewall Rule for Azure Services

To allow Azure services to access the SQL Server:

```hcl
firewall_rules = {
  azure_services = {
    start_ip = "0.0.0.0"
    end_ip   = "0.0.0.0"
  }
}
```

## VNet Rule Requirements

The subnet must have the `Microsoft.Sql` service endpoint enabled:

```hcl
module "subnet_app" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/subnet?ref=v1.0.0"
  
  name                 = "${module.naming.subnet}-app"
  resource_group_name  = module.rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  
  service_endpoints = ["Microsoft.Sql"]
}
```
