# Managed Disk Module

Terraform module to create Azure Managed Disks.

## Features

- All storage tiers (Standard/Premium SSD, Ultra SSD)
- Zone redundancy (ZRS)
- Disk encryption
- Shared disks
- Ultra SSD performance configuration
- Bursting support
- Private endpoint support

## Usage

### Standard Data Disk

```hcl
module "disk_data" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/disk?ref=v1.0.0"
  
  name                 = "${module.naming.base_name}-disk-data"
  resource_group_name  = module.rg.name
  location             = var.location
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 256
  
  tags = local.common_tags
}
```

### OS Disk from Image

```hcl
module "disk_os" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/disk?ref=v1.0.0"
  
  name                 = "${module.naming.base_name}-disk-os"
  resource_group_name  = module.rg.name
  location             = "westeurope"
  storage_account_type = "Premium_LRS"
  create_option        = "FromImage"
  image_reference_id   = var.image_id
  disk_size_gb         = 128
  os_type              = "Linux"
  hyper_v_generation   = "V2"
  
  tags = local.common_tags
}
```

### Ultra SSD with Performance Configuration

```hcl
module "disk_ultra" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/disk?ref=v1.0.0"
  
  name                 = "${module.naming.base_name}-disk-ultra"
  resource_group_name  = module.rg.name
  location             = "westeurope"
  storage_account_type = "UltraSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1024
  zone                 = "1"
  
  disk_iops_read_write = 5000
  disk_mbps_read_write = 200
  
  tags = local.common_tags
}
```

### Zone-Redundant Disk

```hcl
module "disk_zrs" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/disk?ref=v1.0.0"
  
  name                 = "${module.naming.base_name}-disk-zrs"
  resource_group_name  = module.rg.name
  location             = "westeurope"
  storage_account_type = "Premium_ZRS"
  create_option        = "Empty"
  disk_size_gb         = 512
  
  tags = local.common_tags
}
```

### Shared Disk

```hcl
module "disk_shared" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/disk?ref=v1.0.0"
  
  name                 = "${module.naming.base_name}-disk-shared"
  resource_group_name  = module.rg.name
  location             = "westeurope"
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 256
  max_shares           = 2
  
  tags = local.common_tags
}
```

### Encrypted Disk with Customer-Managed Key

```hcl
module "disk_encrypted" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/disk?ref=v1.0.0"
  
  name                   = "${module.naming.base_name}-disk-encrypted"
  resource_group_name    = module.rg.name
  location               = "westeurope"
  storage_account_type   = "Premium_LRS"
  create_option          = "Empty"
  disk_size_gb           = 256
  disk_encryption_set_id = module.disk_encryption_set.id
  
  tags = local.common_tags
}
```

### Copy from Existing Disk

```hcl
module "disk_copy" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/disk?ref=v1.0.0"
  
  name                 = "${module.naming.base_name}-disk-copy"
  resource_group_name  = module.rg.name
  location             = "westeurope"
  storage_account_type = "Premium_LRS"
  create_option        = "Copy"
  source_resource_id   = module.disk_source.id
  
  tags = local.common_tags
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| name | Disk name | string | Yes | - |
| resource_group_name | Resource Group | string | Yes | - |
| location | Azure region | string | Yes | - |
| storage_account_type | Storage tier | string | No | Premium_LRS |
| create_option | Creation method | string | No | Empty |
| disk_size_gb | Size in GB | number | No | 128 |
| os_type | OS type | string | No | null |
| zone | Availability zone | string | No | null |
| disk_iops_read_write | IOPS | number | No | null |
| disk_mbps_read_write | Throughput MB/s | number | No | null |
| max_shares | Max shares | number | No | null |
| disk_encryption_set_id | Encryption set | string | No | null |
| tags | Tags | map(string) | No | {} |

## Outputs

| Name | Description |
|------|-------------|
| id | Managed Disk ID |
| name | Managed Disk name |

## Storage Types

| Type | Use Case | Performance |
|------|----------|-------------|
| Standard_LRS | Dev/test, infrequent access | Low cost, HDD |
| StandardSSD_LRS | Web servers, light workloads | Medium cost, SSD |
| Premium_LRS | Production workloads | High performance, SSD |
| Premium_ZRS | Zone-redundant production | High performance + HA |
| UltraSSD_LRS | IO-intensive workloads | Highest IOPS/throughput |

## Performance Tiers

Premium SSD supports changing performance tiers without increasing disk size:

```hcl
module "disk_premium" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/disk?ref=v1.0.0"
  
  name                 = "${module.naming.base_name}-disk-p30"
  resource_group_name  = module.rg.name
  location             = "westeurope"
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 128  # P10 size
  tier                 = "P30" # P30 performance
  
  tags = local.common_tags
}
```

## Attachment Example

```hcl
# Disk
module "disk_data" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/disk?ref=v1.0.0"
  
  name                 = "${module.naming.base_name}-disk-data"
  resource_group_name  = module.rg.name
  location             = "westeurope"
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 256
  
  tags = local.common_tags
}

# Attachment
resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  managed_disk_id    = module.disk_data.id
  virtual_machine_id = module.vm.id
  lun                = 0
  caching            = "ReadWrite"
}
```
