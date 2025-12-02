# Terraform Azure POC

**Versao:** 1.0 POC  
**Data:** 2 de Dezembro de 2025

---

## Objetivo

Proof of Concept (POC) para implementar Infrastructure as Code (IaC) usando Terraform no Azure.

## Estrutura do Repositorio

```
terraform-azure-project/
├── README.md
├── docs/
│   └── README.md              # Este arquivo
├── pipelines/                 # Jenkins pipelines (futuro)
├── scripts/                   # Scripts auxiliares
├── terraform-modules/         # Modulos reutilizaveis
│   ├── vnet/
│   ├── subnet/
│   ├── nsg/
│   ├── ssh/
│   └── vm-linux/
└── template/                  # Template de infraestrutura
    ├── providers.tf
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── environments/
        ├── prd/
        │   └── terraform.tfvars
        └── non-prd/
            └── terraform.tfvars
```

## Modulos Disponiveis

### 1. VNET (Virtual Network)
Cria uma rede virtual no Azure.

**Inputs:**
- `vnet_name` - Nome da VNET
- `location` - Regiao do Azure
- `resource_group_name` - Nome do resource group
- `address_space` - Espaco de enderecamento (CIDR)
- `tags` - Tags para organizacao

**Outputs:**
- `vnet_id` - ID da VNET
- `vnet_name` - Nome da VNET

### 2. Subnet
Cria uma subnet dentro da VNET.

**Inputs:**
- `subnet_name` - Nome da subnet
- `resource_group_name` - Nome do resource group
- `virtual_network_name` - Nome da VNET
- `address_prefixes` - Prefixos de enderecamento

**Outputs:**
- `subnet_id` - ID da subnet
- `subnet_name` - Nome da subnet

### 3. NSG (Network Security Group)
Cria um grupo de seguranca de rede.

**Inputs:**
- `nsg_name` - Nome do NSG
- `location` - Regiao do Azure
- `resource_group_name` - Nome do resource group
- `subnet_id` - ID da subnet (opcional)
- `tags` - Tags

**Outputs:**
- `nsg_id` - ID do NSG
- `nsg_name` - Nome do NSG

### 4. SSH Rule
Adiciona regra de SSH ao NSG.

**Inputs:**
- `rule_name` - Nome da regra
- `priority` - Prioridade (default: 1001)
- `source_address_prefix` - IP/CIDR de origem
- `resource_group_name` - Nome do resource group
- `network_security_group_name` - Nome do NSG

**Outputs:**
- `rule_id` - ID da regra
- `rule_name` - Nome da regra

### 5. VM Linux
Cria uma maquina virtual Linux.

**Inputs:**
- `vm_name` - Nome da VM
- `location` - Regiao do Azure
- `resource_group_name` - Nome do resource group
- `vm_size` - Tamanho da VM
- `admin_username` - Usuario admin
- `ssh_public_key` - Chave SSH publica
- `subnet_id` - ID da subnet
- `enable_public_ip` - Habilitar IP publico (true/false)
- `os_disk_type` - Tipo de disco (Standard_LRS/Premium_LRS)
- `tags` - Tags

**Outputs:**
- `vm_id` - ID da VM
- `vm_name` - Nome da VM
- `private_ip_address` - IP privado
- `public_ip_address` - IP publico (se habilitado)

## Quick Start

### 1. Pre-requisitos

```bash
# Azure CLI
az login

# Terraform
terraform version  # >= 1.5.0
```

### 2. Gerar chave SSH

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_vm_key
cat ~/.ssh/azure_vm_key.pub  # Copiar conteudo
```

### 3. Configurar ambiente

Edite o arquivo de variaveis do ambiente desejado:

```bash
# Non-PRD
vim template/environments/non-prd/terraform.tfvars

# PRD
vim template/environments/prd/terraform.tfvars
```

Cole sua chave SSH publica no campo `ssh_public_key`.

### 4. Deploy

```bash
cd template

# Inicializar
terraform init

# Non-PRD
terraform plan -var-file="environments/non-prd/terraform.tfvars"
terraform apply -var-file="environments/non-prd/terraform.tfvars"

# PRD
terraform plan -var-file="environments/prd/terraform.tfvars"
terraform apply -var-file="environments/prd/terraform.tfvars"
```

### 5. Acessar VM

```bash
# Obter IP publico
terraform output vm_public_ip

# Conectar via SSH
ssh -i ~/.ssh/azure_vm_key azureuser@<IP>
```

### 6. Destruir infraestrutura

```bash
terraform destroy -var-file="environments/<env>/terraform.tfvars"
```

## Diferencas entre Ambientes

| Item | Non-PRD | PRD |
|------|---------|-----|
| **Regiao** | West US | East US |
| **VNET CIDR** | 10.1.0.0/16 | 10.0.0.0/16 |
| **Subnet CIDR** | 10.1.1.0/24 | 10.0.1.0/24 |
| **VM Size** | Standard_B2s (econômico) | Standard_D2s_v3 (performance) |
| **Disk Type** | Standard_LRS | Premium_LRS |

## Boas Praticas

### Organizacao de Modulos
- Cada modulo em seu proprio diretorio
- `main.tf` - Recursos principais
- `variables.tf` - Declaracao de variaveis
- `outputs.tf` - Outputs do modulo

### Nomenclatura
- Usar prefixo para todos os recursos: `${prefix}-<tipo>-${environment}`
- Exemplos: `myproject-vnet-prd`, `myproject-vm-non-prd`

### Variaveis
- Usar variaveis para tudo que pode mudar entre ambientes
- Fornecer valores default quando apropriado
- Documentar todas as variaveis

### Tags
- Sempre adicionar tags aos recursos:
  - `Environment` - Ambiente (Production/Non-Production)
  - `ManagedBy` - Terraform
  - `Project` - Nome do projeto
  - `CostCenter` - Centro de custo

## Proximos Passos

Esta e uma POC. Proximas etapas incluem:

1. **Backend Remoto** - Configurar Azure Storage para state
2. **CI/CD** - Implementar pipelines Jenkins
3. **Modulos Adicionais** - Criar mais modulos conforme necessidade
4. **Seguranca** - Adicionar scanning de seguranca (tfsec, checkov)
5. **Documentacao** - Expandir documentacao conforme projeto cresce

## Comandos Uteis

```bash
# Formatar codigo
terraform fmt -recursive

# Validar configuracao
terraform validate

# Ver estado atual
terraform show

# Listar recursos
terraform state list

# Ver output especifico
terraform output <nome>

# Ver plano sem aplicar
terraform plan

# Aplicar apenas um recurso
terraform apply -target=module.vm
```

## Suporte

Para duvidas ou problemas, consulte:
- Documentacao oficial: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- Azure CLI: https://docs.microsoft.com/cli/azure/
