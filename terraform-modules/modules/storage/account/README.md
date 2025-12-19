# Storage Account Module

Terraform module to create and manage Azure Storage Accounts with advanced security options.

## Features

- Multiple storage types: Blob, File, Queue, Table
- Flexible replication options (LRS, GRS, ZRS, etc.)
- Security configurations (TLS, HTTPS, network rules)
- Blob versioning and soft delete
- Advanced Threat Protection
- Infrastructure encryption

## Usage

### Basic Example (POC)

```hcl
module "storage" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/storage/account?ref=v1.0.0"
  
  name                = module.naming.storage_account
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  
  containers = {
    data = {
      access_type = "private"
    }
    logs = {
      access_type = "private"
    }
  }
  
  tags = local.common_tags
}
```

### Production Example (All Security Features)

```hcl
module "storage_production" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/storage/account?ref=v1.0.0"
  
  name                = module.naming.storage_account
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  
  # Storage configuration
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"
  
  # Security settings
  min_tls_version                   = "TLS1_2"
  enable_https_traffic_only         = true
  public_network_access_enabled     = false
  enable_infrastructure_encryption  = true
  enable_advanced_threat_protection = true
  
  # Network rules
  network_rules = {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = ["203.0.113.0/24"]
    virtual_network_subnet_ids = [azurerm_subnet.private.id]
  }
  
  # Blob properties
  blob_properties = {
    versioning_enabled              = true
    change_feed_enabled             = true
    last_access_time_enabled        = true
    delete_retention_days           = 30
    container_delete_retention_days = 30
  }
  
  # Containers
  containers = {
    data = {
      access_type = "private"
    }
    backups = {
      access_type = "private"
    }
  }
  
  # File shares
  shares = {
    "documents" = {
      quota = 100
    }
  }
  
  # Queues
  queues = ["processing", "notifications"]
  
  # Tables
  tables = ["logs", "metrics"]
  
  tags = local.common_tags
}
```

### With Premium Storage

```hcl
module "storage_premium" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/storage/account?ref=v1.0.0"
  
  name                = module.naming.storage_account
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  
  account_tier             = "Premium"
  account_replication_type = "ZRS"
  account_kind             = "BlockBlobStorage"
  
  containers = {
    highperf = {
      access_type = "private"
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
| name | Storage Account name | string | - | yes |
| resource_group_name | Resource Group name | string | - | yes |
| location | Azure region | string | - | yes |
| account_tier | Storage Account tier (Standard, Premium) | string | Standard | no |
| account_replication_type | Replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS) | string | LRS | no |
| account_kind | Storage Account kind (StorageV2, BlobStorage, BlockBlobStorage, FileStorage) | string | StorageV2 | no |
| access_tier | Access tier (Hot, Cool) | string | Hot | no |
| min_tls_version | Minimum TLS version | string | TLS1_2 | no |
| enable_https_traffic_only | Enable HTTPS traffic only | bool | true | no |
| public_network_access_enabled | Enable public network access | bool | true | no |
| enable_infrastructure_encryption | Enable infrastructure encryption | bool | false | no |
| enable_advanced_threat_protection | Enable Advanced Threat Protection | bool | false | no |
| network_rules | Network rules configuration | object | null | no |
| blob_properties | Blob properties configuration | object | see variables.tf | no |
| containers | Map of containers to create | map(object) | {} | no |
| shares | Map of file shares to create | map(object) | {} | no |
| queues | List of queues to create | list(string) | [] | no |
| tables | List of tables to create | list(string) | [] | no |
| tags | Tags to apply to resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Storage Account ID |
| name | Storage Account name |
| primary_blob_endpoint | Primary blob endpoint |
| primary_file_endpoint | Primary file endpoint |
| primary_queue_endpoint | Primary queue endpoint |
| primary_table_endpoint | Primary table endpoint |
| primary_access_key | Primary access key (sensitive) |
| secondary_access_key | Secondary access key (sensitive) |
| primary_connection_string | Primary connection string (sensitive) |
| container_ids | Map of container names to IDs |
| share_ids | Map of share names to IDs |
| queue_ids | Map of queue names to IDs |
| table_ids | Map of table names to IDs |

## Security Best Practices

### For POC/Development
- `public_network_access_enabled = true` (default)
- `enable_infrastructure_encryption = false` (default)
- `enable_advanced_threat_protection = false` (default)
- `blob_properties.versioning_enabled = false` (default)

### For Production
- `public_network_access_enabled = false`
- `enable_infrastructure_encryption = true`
- `enable_advanced_threat_protection = true`
- `blob_properties.versioning_enabled = true`
- `blob_properties.delete_retention_days = 30`
- Configure `network_rules` with subnet restrictions
- Use Private Endpoints (additional configuration required)

## Notes

- Storage account names must be globally unique and 3-24 characters (lowercase letters and numbers only)
- Infrastructure encryption cannot be changed after storage account creation
- Advanced Threat Protection incurs additional costs
- Premium storage only supports certain storage kinds (BlockBlobStorage, FileStorage)
- ZRS and GZRS are not available in all regions

## Migration from Old Structure

Old path: `modules/storage`
New path: `modules/storage/account`

Update your module sources:

```hcl
# Old
module "storage" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/storage?ref=v1.0.0"
}

# New
module "storage" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/storage/account?ref=v2.0.0"
}
```
