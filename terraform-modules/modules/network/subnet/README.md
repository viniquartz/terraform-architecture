# Subnet Module

Módulo Terraform para criar uma Subnet no Azure.

## Características

- ✅ Subnet individual
- ✅ Service endpoints configuráveis
- ✅ Políticas de private endpoint

## Uso

```hcl
module "subnet" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/subnet?ref=v1.0.0"
  
  name                 = "snet-app-tst-brazilsouth-01"
  resource_group_name  = "rg-myapp-tst-brazilsouth-01"
  virtual_network_name = "vnet-myapp-tst-brazilsouth-01"
  address_prefixes     = ["10.0.1.0/24"]
  
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault"
  ]
}
```

## Inputs

| Nome | Descrição | Tipo | Obrigatório | Default |
|------|-----------|------|-------------|---------|
| name | Subnet name | string | Sim | - |
| resource_group_name | Resource Group name | string | Sim | - |
| virtual_network_name | Virtual Network name | string | Sim | - |
| address_prefixes | Address prefixes | list(string) | Sim | - |
| service_endpoints | Service endpoints | list(string) | Não | [] |
| private_endpoint_network_policies_enabled | Enable private endpoint policies | bool | Não | true |

## Outputs

| Nome | Descrição |
|------|-----------|
| id | Subnet ID |
| name | Subnet name |
| address_prefixes | Subnet address prefixes |
