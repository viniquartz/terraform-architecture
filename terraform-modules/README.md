# Terraform Azure Modules

Reusable Terraform modules for Azure infrastructure following Cloud Adoption Framework best practices.

## Module Organization

Modules are organized by category for better discoverability and maintenance:

```text
modules/
├── foundation/
│   └── naming/              # Naming convention module
├── network/
│   ├── vnet/                # Virtual Network
│   └── nsg/                 # Network Security Group
├── compute/
│   └── vm/                  # Virtual Machine
├── storage/
│   └── account/             # Storage Account (Blob, File, Queue, Table)
├── container/
│   └── acr/                 # Azure Container Registry
├── database/                # (coming soon: SQL, PostgreSQL, Cosmos DB)
├── security/                # (coming soon: Key Vault, Firewall)
└── monitoring/              # (coming soon: Log Analytics, App Insights)
```

## Quick Start

### Using Modules with Git Source (Production)

```hcl
module "naming" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/foundation/naming?ref=v1.0.0"
  
  environment     = "prd"
  project_name    = "myapp"
  project_version = "01"
  location        = "brazilsouth"
}

module "storage" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/storage/account?ref=v1.0.0"
  
  name                     = module.naming.storage_account
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  containers = {
    data = {
      access_type = "private"
    }
  }
}
```

### Using Local Modules (Development/POC)

```hcl
module "naming" {
  source = "../../terraform-modules/modules/foundation/naming"
  
  environment     = "tst"
  project_name    = "myapp"
  project_version = "01"
  location        = "brazilsouth"
}

module "vnet" {
  source = "../../terraform-modules/modules/network/vnet"
  
  name                = module.naming.virtual_network
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  
  subnets = {
    app = {
      address_prefixes = ["10.0.1.0/24"]
    }
  }
}
```

## Module Naming Convention

Standard: `azr_<environment>_<projectName><projectVersion>_<regionAbbr>_<resourceType>[suffix]`

**Examples:**
- `azr_prd_datalake01_brs_rg` (Resource Group)
- `azr_prd_datalake01_brs_vnet` (Virtual Network)
- `azr_prd_datalake01_brs_vm01` (Virtual Machine with suffix)
- `azrprddatalake01brsst` (Storage Account - no underscores)

## Module Features

### Foundation

#### naming
- 64+ Azure region abbreviations
- 23+ resource type abbreviations
- Special handling for Storage, Key Vault, ACR
- Optional suffix for multiple instances

### Network

#### vnet
- Dynamic subnet creation
- Service endpoints support
- DNS servers configuration
- Full VNet peering support (configure separately)

#### nsg
- Dynamic security rule creation
- Priority auto-management
- Support for all rule types

### Compute

#### vm
- Linux VM with NIC
- SSH authentication
- Custom VM sizes
- Managed disk support

### Storage

#### account
- Blob, File, Queue, Table support
- Multiple replication options (LRS, GRS, ZRS, GZRS, RAGRS, RAGZRS)
- Advanced security features (TLS 1.2, HTTPS only)
- Blob versioning and soft delete
- Network rules and Private Endpoints support
- Advanced Threat Protection
- Infrastructure encryption

### Container

#### acr
- Basic, Standard, Premium SKU
- Geo-replication support
- Admin user option
- Container scanning (Premium)

## Security Defaults

All modules are configured with security best practices but with POC-friendly defaults:

### For POC/Development (Default)
- Public network access: **Enabled**
- Infrastructure encryption: **Disabled**
- Advanced Threat Protection: **Disabled**
- Blob versioning: **Disabled**

### For Production (Opt-in)
- Public network access: **Disabled**
- Infrastructure encryption: **Enabled**
- Advanced Threat Protection: **Enabled**
- Blob versioning: **Enabled**
- Network rules: **Configured**
- Private Endpoints: **Enabled**

Example production storage configuration:

```hcl
module "storage_production" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/storage/account?ref=v1.0.0"
  
  name                = module.naming.storage_account
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  
  # Production security settings
  public_network_access_enabled     = false
  enable_infrastructure_encryption  = true
  enable_advanced_threat_protection = true
  
  network_rules = {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = []
    virtual_network_subnet_ids = [azurerm_subnet.private.id]
  }
  
  blob_properties = {
    versioning_enabled              = true
    change_feed_enabled             = true
    last_access_time_enabled        = true
    delete_retention_days           = 30
    container_delete_retention_days = 30
  }
  
  containers = {
    data = { access_type = "private" }
  }
}
```

## Module Versioning

All modules follow semantic versioning (v1.0.0, v1.1.0, etc.).

**Version Tags:**
- `v1.0.0` - Initial release
- `v1.1.0` - New features (backward compatible)
- `v2.0.0` - Breaking changes

**Usage:**

```hcl
# Pin to specific version (recommended for production)
module "naming" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/foundation/naming?ref=v1.0.0"
}

# Use latest (not recommended for production)
module "naming" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/foundation/naming?ref=main"
}
```

## Requirements

All modules require:
- Terraform >= 1.5.0
- azurerm provider ~> 3.0

## Module Documentation

Each module has its own README with:
- Usage examples
- Input variables
- Output values
- Requirements
- Security best practices

**Module READMEs:**
- [foundation/naming](modules/foundation/naming/README.md)
- [storage/account](modules/storage/account/README.md)
- network/vnet (coming soon)
- network/nsg (coming soon)
- compute/vm (coming soon)
- container/acr (coming soon)

## Migration Guide

### From Flat Structure to Categorized

Old paths → New paths:

```hcl
# naming
modules/naming → modules/foundation/naming

# network
modules/vnet → modules/network/vnet
modules/nsg → modules/network/nsg

# compute
modules/vm → modules/compute/vm

# storage
modules/storage → modules/storage/account

# container
modules/acr → modules/container/acr
```

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

## Contributing

When adding new modules:

1. Place in appropriate category
2. Follow existing structure: `variables.tf`, `main.tf`, `outputs.tf`, `README.md`
3. Include security options (disabled by default for POC)
4. Add comprehensive README with examples
5. Use semantic versioning

## Roadmap

### Phase 2 - Database
- SQL Server
- PostgreSQL
- MySQL
- Cosmos DB
- Redis Cache

### Phase 3 - Security
- Key Vault
- Firewall
- Bastion Host
- WAF

### Phase 4 - Monitoring
- Log Analytics Workspace
- Application Insights
- Dashboard
- Action Groups

### Phase 5 - Integration
- Event Hub
- Service Bus
- API Management
- Data Factory

## Support

For issues or questions:
1. Check module README
2. Review examples in terraform-project-template
3. Consult architecture documentation in `/docs`
4. Open issue in repository
