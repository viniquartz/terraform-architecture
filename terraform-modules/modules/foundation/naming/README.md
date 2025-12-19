# Naming Module

Generates standardized Azure resource names following the pattern:
`azr_<environment>_<projectName><projectVersion>_<regionAbbr>_<resourceType>[suffix]`

## Example Names

```
azr_prd_datalake01_weu_rg
azr_prd_datalake01_weu_vm01
azr_prd_datalake01_weu_vnet
azrprddatalake01weust01  (storage account - no underscores)
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
  # Result: azr_prd_datalake01_weu_vm_01, azr_prd_datalake01_weu_vm_02, etc
}
```

### Multiple Instances with For Each

```hcl
locals {
  vm_names = ["web", "api", "worker"]
}

module "naming_vm" {
  source   = "../modules/naming"
  for_each = toset(local.vm_names)
  
  environment     = "prd"
  project_name    = "datalake"
  project_version = "01"
  location        = "westeurope"
  suffix          = each.value
}

resource "azurerm_linux_virtual_machine" "vms" {
  for_each = toset(local.vm_names)
  
  name = module.naming_vm[each.key].virtual_machine
  # Result: azr_prd_datalake01_weu_vm_web, azr_prd_datalake01_weu_vm_api, etc
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| environment | Environment (prd/qlt/tst) | string | Yes |
| project_name | Project name | string | Yes |
| project_version | Project version (01, 02) | string | No (default: "01") |
| location | Azure region | string | Yes |
| suffix | Optional suffix for multiple instances | string | No (default: "") |

## Outputs

| Name | Description | Example |
|------|-------------|---------|
| resource_group | Resource Group name | azr_prd_datalake01_weu_rg |
| virtual_machine | VM name | azr_prd_datalake01_weu_vm01 |
| virtual_network | VNet name | azr_prd_datalake01_weu_vnet |
| subnet | Subnet name | azr_prd_datalake01_weu_snet |
| storage_account | Storage Account name | azrprddatalake01weust01 |
| container_registry | ACR name | azrprddatalake01weuacr01 |

See `outputs.tf` for complete list.

## Region Abbreviations

| Region | Code | Region | Code |
|--------|------|--------|------|
| West Europe | weu | Brazil South | brs |
| North Europe | neu | East US | eus |
| West US 2 | wu2 | Southeast Asia | sea |

See `locals.tf` for complete list.
