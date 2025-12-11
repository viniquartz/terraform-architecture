# Backend e State Files - Guia de Administracao

## O Que É

**Backend**: Onde o Terraform guarda o estado (state file) dos recursos criados.

**State File**: Arquivo JSON que mapeia seus recursos Terraform com recursos reais no Azure.

## Arquitetura

```
Azure Storage Account: stterraformstate
├── Resource Group: rg-terraform-state
├── Container: terraform-state-prd
│   ├── project-a/terraform.tfstate
│   ├── project-b/terraform.tfstate
│   └── project-c/terraform.tfstate
├── Container: terraform-state-qlt
│   └── (mesma estrutura)
└── Container: terraform-state-tst
    └── (mesma estrutura)
```

## Configuracao Inicial

### 1. Criar Infrastructure de Backend

```bash
# Executar uma vez
cd scripts/setup
./configure-azure-backend.sh

# Resultado:
# - Resource Group: rg-terraform-state
# - Storage Account: stterraformstate
# - Containers: terraform-state-prd, terraform-state-qlt, terraform-state-tst
```

### 2. Criar Service Principals

```bash
# Criar SPs para cada ambiente
./create-service-principals.sh

# Resultado:
# - sp-terraform-prd (Contributor)
# - sp-terraform-qlt (Contributor)
# - sp-terraform-tst (Contributor)
# - Credenciais salvas em .credentials/
```

### 3. Configurar Credenciais

```bash
# Ver credenciais geradas
cat .credentials/jenkins-credentials.txt

# Adicionar no Jenkins ou exportar localmente
export ARM_CLIENT_ID="client-id-do-sp"
export ARM_CLIENT_SECRET="secret-do-sp"
export ARM_TENANT_ID="tenant-id"
export ARM_SUBSCRIPTION_ID="subscription-id"
```

## Como Funciona

### Backend Dinamico

Cada projeto usa backend.tf vazio:

```hcl
terraform {
  backend "azurerm" {
    # Configurado dinamicamente por scripts
  }
}
```

Scripts injetam valores em runtime:

```bash
# Script cria backend-config.tfbackend
resource_group_name  = "rg-terraform-state"
storage_account_name = "stterraformstate"
container_name       = "terraform-state-prd"
key                  = "my-project/terraform.tfstate"

# Terraform init usa esse arquivo
terraform init -backend-config=backend-config.tfbackend
```

### Organizacao de States

Regra: Um state file por projeto por ambiente

```
projeto-a em TST: terraform-state-tst/projeto-a/terraform.tfstate
projeto-a em PRD: terraform-state-prd/projeto-a/terraform.tfstate
projeto-b em PRD: terraform-state-prd/projeto-b/terraform.tfstate
```

## Seguranca

### Acesso por Ambiente

- **PRD**: Apenas pipeline CI/CD e SRE
- **QLT**: Desenvolvedores + Pipeline
- **TST**: Todos os desenvolvedores

### Service Principals

Cada ambiente tem SP proprio:
- sp-terraform-prd: Apenas PRD
- sp-terraform-qlt: Apenas QLT
- sp-terraform-tst: Apenas TST

### Protecoes

- Soft delete: 30 dias
- Versioning: Habilitado
- TLS 1.2 minimo
- Acesso publico: Desabilitado

## Operacoes Comuns

### Ver State File

```bash
# Baixar state
terraform state pull > current-state.json

# Ver recursos
terraform state list

# Ver detalhes de um recurso
terraform state show azurerm_resource_group.main
```

### Backup Manual

```bash
# States tem versioning automatico no Azure
# Para backup manual:
terraform state pull > backup-$(date +%Y%m%d).json
```

### Restaurar State

```bash
# Listar versoes disponiveis
az storage blob list \
  --account-name stterraformstate \
  --container-name terraform-state-prd \
  --prefix my-project/ \
  --include v

# Baixar versao especifica
az storage blob download \
  --account-name stterraformstate \
  --container-name terraform-state-prd \
  --name my-project/terraform.tfstate \
  --version-id <version-id> \
  --file terraform.tfstate.backup
```

### Liberar Lock Travado

```bash
# Se state ficar locked
terraform force-unlock <LOCK_ID>

# LOCK_ID aparece no erro
```

### Mover Recurso no State

```bash
# Renomear recurso no state
terraform state mv azurerm_resource_group.old azurerm_resource_group.new

# Remover recurso do state (sem destruir)
terraform state rm azurerm_resource_group.test
```

### Importar Recurso Existente

```bash
# Recurso criado fora do Terraform
terraform import azurerm_resource_group.main /subscriptions/{sub-id}/resourceGroups/rg-name
```

## Troubleshooting

### State Corrompido

```bash
# 1. Verificar versoes anteriores
az storage blob list --include v ...

# 2. Restaurar versao anterior
az storage blob download --version-id ...

# 3. Validar state restaurado
terraform plan
```

### Lock Travado

```bash
# Causa: Pipeline interrompido ou rede
# Solucao:
terraform force-unlock <LOCK_ID>
```

### State Inconsistente

```bash
# Recurso existe no Azure mas nao no state
terraform import ...

# Recurso no state mas nao existe no Azure
terraform state rm ...
```

### Backend Inacessivel

```bash
# Verificar credenciais
az login
az account show

# Testar acesso ao storage
az storage blob list \
  --account-name stterraformstate \
  --container-name terraform-state-tst
```

## Monitoramento

### Metricas Importantes

```bash
# Tamanho dos state files
az storage blob list \
  --account-name stterraformstate \
  --container-name terraform-state-prd \
  --query "[].{Name:name, Size:properties.contentLength}"

# Ultima modificacao
az storage blob show \
  --account-name stterraformstate \
  --container-name terraform-state-prd \
  --name my-project/terraform.tfstate \
  --query "properties.lastModified"
```

### Alertas Recomendados

- State modificado em PRD fora do horario
- Lock duration > 15 minutos
- State file > 10 MB
- Falhas de acesso

## Boas Praticas

### Fazer

- Sempre usar backend remoto
- Um state por projeto
- Testar em TST antes de PRD
- Revisar planos antes de apply
- Manter credenciais seguras
- Usar CI/CD para PRD

### Evitar

- Editar state manualmente
- Compartilhar state entre projetos
- Force-unlock sem investigar
- State local em time
- Commit de state no Git
- Applies simultaneos no mesmo state

## Manutencao

### Diaria

- Monitorar pipelines
- Verificar alertas

### Semanal

- Revisar tamanho dos states
- Verificar backups (versioning)
- Limpar states de projetos descontinuados

### Mensal

- Auditoria de acessos
- Revisar permissoes
- Testar procedimentos de recuperacao

## Contatos

- **SRE Team**: Problemas com backend
- **Platform Engineering**: Duvidas sobre setup
- **Security**: Problemas com credenciais

## Referencias

- Template de projeto: terraform-project-template/
- Scripts de setup: scripts/setup/
- Scripts de deploy: scripts/deployment/
