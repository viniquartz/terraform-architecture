# Terraform Azure POC

Proof of Concept para Infrastructure as Code no Azure usando Terraform.

## Estrutura

```
terraform-azure-project/
├── terraform-modules/     # 5 modulos reutilizaveis
│   ├── vnet/
│   ├── subnet/
│   ├── nsg/
│   ├── ssh/
│   └── vm-linux/
└── template/             # Template de infraestrutura
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── providers.tf
    └── environments/
        ├── prd/
        │   └── terraform.tfvars
        └── non-prd/
            └── terraform.tfvars
```

## Quick Start

### 1. Pre-requisitos

```bash
# Azure CLI
az login

# Terraform >= 1.5.0
terraform version
```

### 2. Gerar chave SSH

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_vm_key
cat ~/.ssh/azure_vm_key.pub  # Copiar conteudo
```

### 3. Configurar ambiente

```bash
cd template

# Editar variaveis do ambiente
vim environments/non-prd/terraform.tfvars  # ou prd

# Colar sua chave SSH publica no campo ssh_public_key
```

### 4. Deploy

```bash
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
terraform output vm_public_ip
ssh -i ~/.ssh/azure_vm_key azureuser@<IP>
```

## Modulos Disponiveis

- **vnet** - Virtual Network
- **subnet** - Subnet
- **nsg** - Network Security Group
- **ssh** - SSH Security Rule
- **vm-linux** - Linux Virtual Machine

Veja detalhes em [`docs/README.md`](docs/README.md)

## Proximos Passos

- [ ] Adicionar backend remoto (Azure Storage)
- [ ] Configurar pipelines CI/CD
- [ ] Adicionar mais modulos
- [ ] Implementar testes automatizados
