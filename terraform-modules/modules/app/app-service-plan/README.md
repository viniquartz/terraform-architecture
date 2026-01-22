# App Service Plan Module

Terraform module to create Azure App Service Plan (Service Plan).

## Features

- Windows and Linux support
- Basic, Standard, Premium (v2/v3) tiers
- Elastic scaling
- Zone redundancy
- Per-site scaling
- App Service Environment support

## Usage

### Basic Linux Plan

```hcl
module "app_service_plan" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/app/app-service-plan?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-asp"
  resource_group_name = module.rg.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "B1"
  
  tags = local.common_tags
}
```

### Premium v3 with Zone Redundancy

```hcl
module "app_service_plan_premium" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/app/app-service-plan?ref=v1.0.0"
  
  name                   = "${module.naming.base_name}-asp-premium"
  resource_group_name    = module.rg.name
  location               = "westeurope"
  os_type                = "Linux"
  sku_name               = "P1v3"
  zone_balancing_enabled = true
  worker_count           = 3
  
  tags = local.common_tags
}
```

### Windows Plan with Elastic Scaling

```hcl
module "app_service_plan_windows" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/app/app-service-plan?ref=v1.0.0"
  
  name                         = "${module.naming.base_name}-asp-win"
  resource_group_name          = module.rg.name
  location                     = "westeurope"
  os_type                      = "Windows"
  sku_name                     = "P2v3"
  maximum_elastic_worker_count = 10
  
  tags = local.common_tags
}
```

### Consumption Plan (Functions Y1)

```hcl
module "app_service_plan_consumption" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/app/app-service-plan?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-asp-func"
  resource_group_name = module.rg.name
  location            = "westeurope"
  os_type             = "Windows"
  sku_name            = "Y1"
  
  tags = local.common_tags
}
```

### With Per-Site Scaling

```hcl
module "app_service_plan_multi" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/app/app-service-plan?ref=v1.0.0"
  
  name                     = "${module.naming.base_name}-asp-multi"
  resource_group_name      = module.rg.name
  location                 = "westeurope"
  os_type                  = "Linux"
  sku_name                 = "P1v3"
  per_site_scaling_enabled = true
  worker_count             = 3
  
  tags = local.common_tags
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| name | Plan name | string | Yes | - |
| resource_group_name | Resource Group | string | Yes | - |
| location | Azure region | string | Yes | - |
| os_type | OS type | string | Yes | - |
| sku_name | SKU name | string | Yes | - |
| worker_count | Worker count | number | No | null |
| maximum_elastic_worker_count | Max elastic workers | number | No | null |
| per_site_scaling_enabled | Per-site scaling | bool | No | false |
| zone_balancing_enabled | Zone balancing | bool | No | false |
| tags | Tags | map(string) | No | {} |

## Outputs

| Name | Description |
|------|-------------|
| id | App Service Plan ID |
| name | App Service Plan name |

## SKU Names

### Basic

- **B1**: 1 Core, 1.75 GB RAM
- **B2**: 2 Cores, 3.5 GB RAM
- **B3**: 4 Cores, 7 GB RAM

### Standard

- **S1**: 1 Core, 1.75 GB RAM
- **S2**: 2 Cores, 3.5 GB RAM
- **S3**: 4 Cores, 7 GB RAM

### Premium v2

- **P1v2**: 1 Core, 3.5 GB RAM
- **P2v2**: 2 Cores, 7 GB RAM
- **P3v2**: 4 Cores, 14 GB RAM

### Premium v3

- **P1v3**: 2 Cores, 8 GB RAM
- **P2v3**: 4 Cores, 16 GB RAM
- **P3v3**: 8 Cores, 32 GB RAM

### Isolated v2 (Requires ASE)

- **I1v2**: 2 Cores, 8 GB RAM
- **I2v2**: 4 Cores, 16 GB RAM
- **I3v2**: 8 Cores, 32 GB RAM

### Consumption (Functions)

- **Y1**: Consumption plan

## Zone Balancing

Zone balancing requires:

- Premium v2 or v3 SKU
- Minimum 3 instances (worker_count = 3)
- Region with availability zones

```hcl
module "app_service_plan_ha" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/app/app-service-plan?ref=v1.0.0"
  
  name                   = "${module.naming.base_name}-asp-ha"
  resource_group_name    = module.rg.name
  location               = "westeurope"
  os_type                = "Linux"
  sku_name               = "P1v3"
  worker_count           = 3
  zone_balancing_enabled = true
  
  tags = local.common_tags
}
```

## Per-Site Scaling

Allows individual apps to scale independently:

```hcl
module "app_service_plan" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/app/app-service-plan?ref=v1.0.0"
  
  name                     = "${module.naming.base_name}-asp"
  resource_group_name      = module.rg.name
  location                 = "westeurope"
  os_type                  = "Linux"
  sku_name                 = "S1"
  per_site_scaling_enabled = true
  
  tags = local.common_tags
}
```

## Complete Production Example

```hcl
module "app_service_plan_prod" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/app/app-service-plan?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-asp-prod"
  resource_group_name = module.rg.name
  location            = "westeurope"
  os_type             = "Linux"
  sku_name            = "P2v3"
  
  worker_count               = 3
  zone_balancing_enabled     = true
  per_site_scaling_enabled   = false
  maximum_elastic_worker_count = 10
  
  tags = merge(local.common_tags, {
    Tier = "Production"
  })
}
```
