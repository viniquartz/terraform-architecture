# NSG Rule Module

Módulo Terraform para criar uma regra de Network Security Group no Azure.

## Características

- ✅ Regra individual de NSG
- ✅ Validação de parâmetros
- ✅ Suporte a todos os protocolos (Tcp, Udp, Icmp, *)

## Uso

```hcl
module "nsg_rule_ssh" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/nsg-rule?ref=v1.0.0"
  
  name                        = "allow-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "rg-myapp-tst-brazilsouth-01"
  network_security_group_name = "nsg-myapp-tst-brazilsouth-01"
}
```

## Inputs

| Nome | Descrição | Tipo | Obrigatório | Default |
|------|-----------|------|-------------|---------|
| name | Rule name | string | Sim | - |
| priority | Priority (100-4096) | number | Sim | - |
| direction | Inbound or Outbound | string | Sim | - |
| access | Allow or Deny | string | Sim | - |
| protocol | Tcp, Udp, Icmp or * | string | Sim | - |
| source_port_range | Source port range | string | Não | * |
| destination_port_range | Destination port range | string | Sim | - |
| source_address_prefix | Source address prefix | string | Não | * |
| destination_address_prefix | Destination address prefix | string | Não | * |
| resource_group_name | Resource Group name | string | Sim | - |
| network_security_group_name | NSG name | string | Sim | - |

## Outputs

| Nome | Descrição |
|------|-----------|
| id | Security rule ID |
| name | Security rule name |
