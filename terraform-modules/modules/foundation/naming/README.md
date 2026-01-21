# Naming Module

Generates standardized Azure resource names following the pattern:
`azr-<environment>-<projectName><projectVersion>-<regionAbbr>-<resourceType>[-purpose]`

## Example Names

```
azr-prd-datalake01-weu-rg
azr-prd-datalake01-weu-vm-web
azr-prd-datalake01-weu-vnet
azr-prd-datalake01-weu-vm-01
azrprddatalake01weust01  (storage account - no hyphens)
azr-prd-datalake01-weu-vm-api  (with purpose)
```

## Usage

### Single Resource

```hcl
module "naming" {
  source = "../modules/naming"
  
  environment     = "prd"
  project_name    = "datalake"
  project_version = "01"
  location        = "westeurope"
}

resource "azurerm_resource_group" "main" {
  name     = module.naming.resource_group
  location = "westeurope"
}

# Output: azr-prd-datalake01-weu-rg
```

### Single Resource with Purpose

```hcl
module "naming_api" {
  source = "../modules/naming"
  
  environment     = "prd"
  project_name    = "datalake"
  project_version = "01"
  location        = "westeurope"
  purpose         = "api"
}

resource "azurerm_linux_virtual_machine" "api" {
  name = module.naming_api.virtual_machine
  # Output: azr-prd-datalake01-weu-vm-api
}
```

### Multiple Instances with Count

```hcl
module "naming_vm" {
  source = "../modules/naming"
  count  = 3
  
  environment     = "prd"
  project_name    = "datalake"
  project_version = "01"
  location        = "westeurope"
  suffix          = format("%02d", count.index + 1)  # 01, 02, 03
}

resource "azurerm_linux_virtual_machine" "vms" {
  count = 3
  
  name = module.naming_vm[count.index].virtual_machine
  # Result: azr-prd-datalake01-weu-vm-01, azr-prd-datalake01-weu-vm-02, etc
}
```

### Multiple Instances with For Each

```hcl
locals {
  vm_roles = ["web", "api", "worker"]
}

module "naming_vm" {
  source   = "../modules/naming"
  for_each = toset(local.vm_roles)
  
  environment     = "prd"
  project_name    = "datalake"
  project_version = "01"
  location        = "westeurope"
  purpose         = each.value
}

resource "azurerm_linux_virtual_machine" "vms" {
  for_each = toset(local.vm_roles)
  
  name = module.naming_vm[each.key].virtual_machine
  # Result: azr-prd-datalake01-weu-vm-web, azr-prd-datalake01-weu-vm-api, etc
}
```

### Numeric Suffix at End (Manual Concatenation)

When you want numeric suffix at the **end** of the resource name:

```hcl
module "naming" {
  source = "../modules/naming"
  
  environment     = "prd"
  project_name    = "datalake"
  project_version = "01"
  location        = "westeurope"
}

resource "azurerm_virtual_network" "vnet01" {
  name = "${module.naming.virtual_network}-01"
  # Result: azr-prd-datalake01-weu-vnet-01
}
```

### Multiple Resources with Count (Numeric Suffix at End)

```hcl
module "naming" {
  source = "../modules/naming"
  
  environment     = "prd"
  project_name    = "datalake"
  project_version = "01"
  location        = "westeurope"
}

resource "azurerm_virtual_network" "vnets" {
  count = 3
  
  name = "${module.naming.virtual_network}-${format("%02d", count.index + 1)}"
  # Result: 
  # azr-prd-datalake01-weu-vnet-01
  # azr-prd-datalake01-weu-vnet-02
  # azr-prd-datalake01-weu-vnet-03
}
```

### Multiple Resources with For Each (Numeric Suffix at End)

```hcl
locals {
  network_instances = ["01", "02", "03"]
}

module "naming" {
  source = "../modules/naming"
  
  environment     = "prd"
  project_name    = "datalake"
  project_version = "01"
  location        = "westeurope"
}

resource "azurerm_virtual_network" "vnets" {
  for_each = toset(local.network_instances)
  
  name = "${module.naming.virtual_network}-${each.value}"
  # Result: azr-prd-datalake01-weu-vnet-01, 02, 03
}
```

## Suffix vs Purpose vs Manual Concatenation

**When to use each approach:**

| Approach | Position | Example | Use Case |
|----------|----------|---------|----------|
| `suffix` variable | Middle (before resource type) | azr-prd-datalake01-weu-**01**-vnet | Multiple instances of same type |
| `purpose` variable | End | azr-prd-datalake01-weu-vm-**api** | Different functional roles |
| Manual concatenation | End | azr-prd-datalake01-weu-vnet-**01** | Numeric suffix at the end |
| `suffix` + `purpose` | Middle + End | azr-prd-datalake01-weu-**01**-vm-**api** | Multiple instances with roles |

**Recommendations:**

- Use **manual concatenation** (`"${module.naming.resource}-01"`) for numeric suffixes at the end
- Use **`purpose`** for functional descriptions (web, api, db)
- Use **`suffix`** when you need the identifier before the resource type
- Combine **`suffix` + `purpose`** for complex scenarios

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| environment | Environment (prd/qlt/tst) | string | Yes |
| project_name | Project name | string | Yes |
| project_version | Project version (01, 02) | string | No (default: "01") |
| location | Azure region | string | Yes |
| suffix | Optional suffix for multiple instances | string | No (default: "") |
| purpose | Optional purpose description (e.g., web, api, db) | string | No (default: "") |

## Outputs

| Name | Description | Example |
|------|-------------|---------|
| resource_group | Resource Group name | azr-prd-datalake01-weu-rg |
| virtual_machine | VM name | azr-prd-datalake01-weu-vm-01 |
| virtual_network | VNet name | azr-prd-datalake01-weu-vnet |
| subnet | Subnet name | azr-prd-datalake01-weu-snet |
| storage_account | Storage Account name | azrprddatalake01weust01 |
| container_registry | ACR name | azrprddatalake01weuacr01 |

**Note:** Storage Account and Container Registry names have no hyphens due to Azure restrictions.

See `outputs.tf` for complete list.

## Region Abbreviations

| Region | Code | Region | Code |
|--------|------|--------|------|
| West Europe | weu | Brazil South | brs |
| North Europe | neu | East US | eus |
| West US 2 | wu2 | Southeast Asia | sea |

See `locals.tf` for complete list.
