# App Service Module

Terraform module to create Azure App Service (Web App).

## Features

- Linux and Windows support
- Docker container deployment
- VNet integration
- Managed Identity
- Application stacks (Node.js, Python, .NET, Java, PHP, Ruby)
- Health checks
- HTTPS enforcement
- App settings and connection strings

## Usage

### Node.js Linux App

```hcl
module "app_service_node" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/app/app-service?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-app-node"
  resource_group_name = module.rg.name
  location            = var.location
  service_plan_id     = module.app_service_plan.id
  os_type             = "Linux"
  
  application_stack = {
    node_version = "18-lts"
  }
  
  app_settings = {
    WEBSITE_NODE_DEFAULT_VERSION = "~18"
    NODE_ENV                     = "production"
  }
  
  tags = local.common_tags
}
```

### Python Linux App

```hcl
module "app_service_python" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/app/app-service?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-app-python"
  resource_group_name = module.rg.name
  location            = "westeurope"
  service_plan_id     = module.app_service_plan.id
  os_type             = "Linux"
  
  application_stack = {
    python_version = "3.11"
  }
  
  app_settings = {
    PYTHONPATH = "/home/site/wwwroot"
  }
  
  tags = local.common_tags
}
```

### .NET Windows App

```hcl
module "app_service_dotnet" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/app/app-service?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-app-dotnet"
  resource_group_name = module.rg.name
  location            = "westeurope"
  service_plan_id     = module.app_service_plan.id
  os_type             = "Windows"
  
  application_stack = {
    current_stack  = "dotnet"
    dotnet_version = "v7.0"
  }
  
  tags = local.common_tags
}
```

### Docker Container

```hcl
module "app_service_docker" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/app/app-service?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-app-docker"
  resource_group_name = module.rg.name
  location            = "westeurope"
  service_plan_id     = module.app_service_plan.id
  os_type             = "Linux"
  
  application_stack = {
    docker_image     = "myregistry.azurecr.io/myapp"
    docker_image_tag = "latest"
  }
  
  container_registry_use_managed_identity = true
  identity_type                           = "SystemAssigned"
  
  app_settings = {
    DOCKER_REGISTRY_SERVER_URL = "https://myregistry.azurecr.io"
  }
  
  tags = local.common_tags
}
```

### With VNet Integration

```hcl
module "app_service_vnet" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/app/app-service?ref=v1.0.0"
  
  name                      = "${module.naming.base_name}-app-vnet"
  resource_group_name       = module.rg.name
  location                  = "westeurope"
  service_plan_id           = module.app_service_plan.id
  os_type                   = "Linux"
  virtual_network_subnet_id = module.subnet_app.id
  vnet_route_all_enabled    = true
  
  application_stack = {
    node_version = "18-lts"
  }
  
  tags = local.common_tags
}
```

### With Database Connection

```hcl
module "app_service_db" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/app/app-service?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-app-db"
  resource_group_name = module.rg.name
  location            = "westeurope"
  service_plan_id     = module.app_service_plan.id
  os_type             = "Linux"
  
  application_stack = {
    dotnet_version = "7.0"
  }
  
  identity_type = "SystemAssigned"
  
  connection_strings = {
    DefaultConnection = {
      type  = "SQLAzure"
      value = "Server=tcp:${module.sql_server.fqdn},1433;Database=${module.sql_database.name};Authentication=Active Directory Default;"
    }
  }
  
  tags = local.common_tags
}
```

### With Health Check

```hcl
module "app_service_hc" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/app/app-service?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-app"
  resource_group_name = module.rg.name
  location            = "westeurope"
  service_plan_id     = module.app_service_plan.id
  os_type             = "Linux"
  
  health_check_path                 = "/health"
  health_check_eviction_time_in_min = 5
  
  application_stack = {
    node_version = "18-lts"
  }
  
  tags = local.common_tags
}
```

### Private App (No Public Access)

```hcl
module "app_service_private" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/app/app-service?ref=v1.0.0"
  
  name                          = "${module.naming.base_name}-app-private"
  resource_group_name           = module.rg.name
  location                      = "westeurope"
  service_plan_id               = module.app_service_plan.id
  os_type                       = "Linux"
  public_network_access_enabled = false
  virtual_network_subnet_id     = module.subnet_app.id
  
  application_stack = {
    python_version = "3.11"
  }
  
  tags = local.common_tags
}

# Private Endpoint for access
module "private_endpoint_app" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/security/private-endpoint?ref=v1.0.0"
  
  name                           = "${module.naming.base_name}-pe-app"
  resource_group_name            = module.rg.name
  location                       = "westeurope"
  subnet_id                      = module.subnet_private.id
  private_connection_resource_id = module.app_service_private.id
  subresource_names              = ["sites"]
  
  tags = local.common_tags
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| name | App name | string | Yes | - |
| resource_group_name | Resource Group | string | Yes | - |
| location | Azure region | string | Yes | - |
| service_plan_id | Service Plan ID | string | Yes | - |
| os_type | OS type | string | Yes | - |
| https_only | HTTPS only | bool | No | true |
| always_on | Always on | bool | No | true |
| minimum_tls_version | Min TLS | string | No | 1.2 |
| application_stack | App stack | object | No | null |
| app_settings | App settings | map | No | {} |
| connection_strings | Connections | map | No | {} |
| identity_type | Identity | string | No | null |
| tags | Tags | map(string) | No | {} |

## Outputs

| Name | Description |
|------|-------------|
| id | App Service ID |
| name | App Service name |
| default_hostname | Default hostname |
| outbound_ip_addresses | Outbound IPs |
| identity_principal_id | Managed Identity ID |

## Application Stacks

### Linux

- **Node.js**: 14-lts, 16-lts, 18-lts, 20-lts
- **Python**: 3.8, 3.9, 3.10, 3.11, 3.12
- **.NET**: 6.0, 7.0, 8.0
- **Java**: 8, 11, 17, 21
- **PHP**: 8.0, 8.1, 8.2
- **Ruby**: 2.7, 3.0, 3.1

### Windows

- **.NET**: v4.0, v6.0, v7.0, v8.0
- **Node**: 16, 18, 20
- **PHP**: 7.4, 8.0, 8.1, 8.2
- **Java**: 8, 11, 17, 21
- **Python**: 3.8, 3.9, 3.10, 3.11

## VNet Integration Requirements

The integration subnet requires:

- Delegation to `Microsoft.Web/serverFarms`
- Minimum /28 address space
- No NSG restrictions on outbound traffic

```hcl
module "subnet_app" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/subnet?ref=v1.0.0"
  
  name                 = "${module.naming.subnet}-app"
  resource_group_name  = module.rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.5.0/24"]
  
  delegation = {
    name = "webapp-delegation"
    service_delegation = {
      name = "Microsoft.Web/serverFarms"
    }
  }
}
```

## Complete Production Example

```hcl
module "app_service_prod" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/app/app-service?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-app-prod"
  resource_group_name = module.rg.name
  location            = "westeurope"
  service_plan_id     = module.app_service_plan.id
  os_type             = "Linux"
  
  https_only              = true
  minimum_tls_version     = "1.2"
  http2_enabled           = true
  always_on               = true
  ftps_state              = "Disabled"
  remote_debugging_enabled = false
  
  virtual_network_subnet_id = module.subnet_app.id
  vnet_route_all_enabled    = true
  
  health_check_path                 = "/api/health"
  health_check_eviction_time_in_min = 5
  
  application_stack = {
    node_version = "18-lts"
  }
  
  identity_type = "SystemAssigned"
  
  app_settings = {
    NODE_ENV                    = "production"
    WEBSITE_NODE_DEFAULT_VERSION = "~18"
    APPINSIGHTS_INSTRUMENTATIONKEY = module.app_insights.instrumentation_key
  }
  
  connection_strings = {
    DefaultConnection = {
      type  = "SQLAzure"
      value = "Server=tcp:${module.sql_server.fqdn},1433;Database=${module.sql_database.name};"
    }
  }
  
  tags = merge(local.common_tags, {
    Tier = "Production"
  })
}
```
