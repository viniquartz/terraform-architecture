# SQL Database Module

Terraform module to create Azure SQL Database.

## Features

- DTU and vCore models
- Serverless compute
- Hyperscale tier
- Zone redundancy
- Long-term retention
- Point-in-time restore
- Advanced Threat Protection
- Ledger support

## Usage

### General Purpose vCore Database

```hcl
module "sql_database" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/database/sql-database?ref=v1.0.0"
  
  name      = "${module.naming.base_name}-sqldb"
  server_id = module.sql_server.id
  
  sku_name       = "GP_Gen5_2"
  max_size_gb    = 32
  zone_redundant = false
  
  tags = local.common_tags
}
```

### Serverless Database

```hcl
module "sql_database_serverless" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/database/sql-database?ref=v1.0.0"
  
  name      = "${module.naming.base_name}-sqldb-serverless"
  server_id = module.sql_server.id
  
  sku_name                    = "GP_S_Gen5_2"
  max_size_gb                 = 32
  auto_pause_delay_in_minutes = 60
  min_capacity                = 0.5
  
  tags = local.common_tags
}
```

### Business Critical with Read Scale-Out

```hcl
module "sql_database_bc" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/database/sql-database?ref=v1.0.0"
  
  name      = "${module.naming.base_name}-sqldb-bc"
  server_id = module.sql_server.id
  
  sku_name       = "BC_Gen5_4"
  max_size_gb    = 1024
  read_scale     = true
  zone_redundant = true
  
  tags = local.common_tags
}
```

### Hyperscale with Read Replicas

```hcl
module "sql_database_hs" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/database/sql-database?ref=v1.0.0"
  
  name      = "${module.naming.base_name}-sqldb-hs"
  server_id = module.sql_server.id
  
  sku_name           = "HS_Gen5_2"
  read_replica_count = 2
  
  tags = local.common_tags
}
```

### With Long-Term Retention

```hcl
module "sql_database_ltr" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/database/sql-database?ref=v1.0.0"
  
  name      = "${module.naming.base_name}-sqldb"
  server_id = module.sql_server.id
  sku_name  = "GP_Gen5_2"
  
  long_term_retention_policy = {
    weekly_retention  = "P1W"
    monthly_retention = "P1M"
    yearly_retention  = "P1Y"
    week_of_year      = 1
  }
  
  short_term_retention_policy = {
    retention_days = 14
  }
  
  tags = local.common_tags
}
```

### With Advanced Threat Protection

```hcl
module "sql_database_atp" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/database/sql-database?ref=v1.0.0"
  
  name      = "${module.naming.base_name}-sqldb"
  server_id = module.sql_server.id
  sku_name  = "GP_Gen5_2"
  
  threat_detection_policy = {
    state                = "Enabled"
    email_account_admins = "Enabled"
    email_addresses      = ["security@example.com"]
    retention_days       = 30
    storage_endpoint     = module.storage.primary_blob_endpoint
    storage_account_access_key = module.storage.primary_access_key
  }
  
  tags = local.common_tags
}
```

### Point-in-Time Restore

```hcl
module "sql_database_restored" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/database/sql-database?ref=v1.0.0"
  
  name      = "${module.naming.base_name}-sqldb-restored"
  server_id = module.sql_server.id
  
  create_mode                 = "PointInTimeRestore"
  creation_source_database_id = module.sql_database.id
  restore_point_in_time       = "2024-01-15T10:00:00Z"
  
  sku_name = "GP_Gen5_2"
  
  tags = local.common_tags
}
```

### Copy Database

```hcl
module "sql_database_copy" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/database/sql-database?ref=v1.0.0"
  
  name      = "${module.naming.base_name}-sqldb-copy"
  server_id = module.sql_server_secondary.id
  
  create_mode                 = "Copy"
  creation_source_database_id = module.sql_database.id
  
  sku_name = "GP_Gen5_2"
  
  tags = local.common_tags
}
```

### In Elastic Pool

```hcl
module "sql_database_pool" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/database/sql-database?ref=v1.0.0"
  
  name            = "${module.naming.base_name}-sqldb"
  server_id       = module.sql_server.id
  elastic_pool_id = module.elastic_pool.id
  
  tags = local.common_tags
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| name | Database name | string | Yes | - |
| server_id | SQL Server ID | string | Yes | - |
| sku_name | SKU name | string | No | GP_Gen5_2 |
| max_size_gb | Max size GB | number | No | null |
| zone_redundant | Zone redundancy | bool | No | false |
| read_scale | Read scale-out | bool | No | false |
| geo_backup_enabled | Geo backup | bool | No | true |
| transparent_data_encryption_enabled | TDE | bool | No | true |
| tags | Tags | map(string) | No | {} |

## Outputs

| Name | Description |
|------|-------------|
| id | SQL Database ID |
| name | SQL Database name |

## SKU Names

### DTU Model

- **Basic**: Basic
- **Standard**: S0, S1, S2, S3, S4, S6, S7, S9, S12
- **Premium**: P1, P2, P4, P6, P11, P15

### vCore Model

- **General Purpose**: GP_Gen5_2, GP_Gen5_4, GP_Gen5_8, etc.
- **Business Critical**: BC_Gen5_2, BC_Gen5_4, BC_Gen5_8, etc.
- **Hyperscale**: HS_Gen5_2, HS_Gen5_4, HS_Gen5_8, etc.

### Serverless

- **General Purpose Serverless**: GP_S_Gen5_1, GP_S_Gen5_2, GP_S_Gen5_4, etc.

## Retention Policies

### Long-Term Retention Format

- W = Weekly (P1W to P10W)
- M = Monthly (P1M to P120M)
- Y = Yearly (P1Y to P10Y)

```hcl
long_term_retention_policy = {
  weekly_retention  = "P2W"   # 2 weeks
  monthly_retention = "P6M"   # 6 months
  yearly_retention  = "P5Y"   # 5 years
  week_of_year      = 1       # First week of year for yearly backup
}
```

### Short-Term Retention

- Minimum: 1 day (Basic)
- Maximum: 35 days

```hcl
short_term_retention_policy = {
  retention_days           = 14
  backup_interval_in_hours = 12  # Only for Hyperscale
}
```

## Complete Production Example

```hcl
module "sql_database_prod" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/database/sql-database?ref=v1.0.0"
  
  name      = "${module.naming.base_name}-sqldb"
  server_id = module.sql_server.id
  
  sku_name       = "BC_Gen5_4"
  max_size_gb    = 1024
  read_scale     = true
  zone_redundant = true
  
  geo_backup_enabled = true
  storage_account_type = "GeoZone"
  
  transparent_data_encryption_enabled = true
  
  long_term_retention_policy = {
    weekly_retention  = "P1W"
    monthly_retention = "P1M"
    yearly_retention  = "P7Y"
    week_of_year      = 1
  }
  
  short_term_retention_policy = {
    retention_days = 35
  }
  
  threat_detection_policy = {
    state                = "Enabled"
    email_account_admins = "Enabled"
    email_addresses      = ["dba@example.com"]
    retention_days       = 90
  }
  
  tags = local.common_tags
}
```
