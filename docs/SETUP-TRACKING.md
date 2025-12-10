# Terraform Azure - Setup Guide (Work in Progress)

**Status**: [WIP] Documento de construção do projeto - será convertido em documentação após conclusão

---

## Tracking de Progresso

### Fase 1: Infraestrutura Base
- [ ] 1.1 - Azure Backend configurado
- [ ] 1.2 - Service Principals criados (PRD, QA, TST)
- [ ] 1.3 - Resource groups organizados

### Fase 2: Repositórios Git
- [ ] 2.1 - Repositório terraform-azure-project configurado
- [ ] 2.2 - Repositório terraform-azure-modules criado e versionado
- [ ] 2.3 - Branch protection configurada

### Fase 3: Jenkins
- [ ] 3.1 - Docker image buildada e testada
- [ ] 3.2 - Jenkins configurado com Docker agent
- [ ] 3.3 - Pipelines criadas e testadas

### Fase 4: Validação
- [ ] 4.1 - Primeiro deployment executado
- [ ] 4.2 - State management funcionando
- [ ] 4.3 - Pipelines de validação OK

---

## Arquitetura Final

```
┌─────────────┐      ┌─────────────┐      ┌──────────────┐
│   GitLab    │─────▶│   Jenkins   │─────▶│    Azure     │
│             │      │ Docker Agent│      │              │
└─────────────┘      └─────────────┘      └──────────────┘
      │                     │                     │
      │                     │                     │
  2 Repos            Tools Docker          Remote State
  ├─ docs            ├─ Terraform          ├─ PRD
  └─ modules         ├─ TFSec              ├─ QA
                     ├─ Checkov            └─ TST
                     └─ Az CLI
```

---

## PARTE 1: Azure Backend Setup

### Estrutura de Containers e State Files

```
Storage Account: terraformstatestorage
│
├── terraform-state-prd/
│   ├── power-bi/terraform.tfstate
│   ├── digital-cabin/terraform.tfstate
│   └── projeto-X/terraform.tfstate
│
├── terraform-state-qa/
│   ├── power-bi/terraform.tfstate
│   ├── digital-cabin/terraform.tfstate
│   └── projeto-X/terraform.tfstate
│
└── terraform-state-tst/
    ├── power-bi/terraform.tfstate
    ├── digital-cabin/terraform.tfstate
    └── projeto-X/terraform.tfstate
```

**Decisão de Design**:
- **1 container por ambiente** (prd, qa, tst)
- **Keys organizados por projeto** dentro de cada container
- **Cada projeto tem sua própria arquitetura** (power-bi, digital-cabin, projeto-X, etc)
- **Isolamento claro** entre ambientes
- **RBAC granular** - SPs diferentes para cada ambiente
- **Fácil navegação** - todos os projetos de um ambiente juntos
- **Simplicidade** - estrutura flat, fácil de entender e escalar até 20+ projetos

**Por quê simples?**
- Menos overhead de gestão
- Fácil onboarding de novos membros do time
- Keys curtos e diretos (`power-bi/terraform.tfstate`)
- Suficiente para maioria dos casos de uso

**Quando evoluir?**
Se você atingir 20+ projetos ou precisar de governança mais rígida, considere adicionar categorias:
```
terraform-state-prd/
├── apps/power-bi/terraform.tfstate
├── infrastructure/networking/terraform.tfstate
└── data/projeto-X/terraform.tfstate
```
Por enquanto, **YAGNI** (You Aren't Gonna Need It) - mantenha simples!

### 1.1 - Criar Storage Account e Containers

```bash
# Variables
LOCATION="westeurope"
RESOURCE_GROUP="terraform-backend-rg"
STORAGE_ACCOUNT="terraformstatestorage"  # Deve ser globalmente único

# 1. Login
az login

# 2. Criar Resource Group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# 3. Criar Storage Account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --https-only true \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false

# 4. Habilitar Versioning e Soft Delete
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 14

# 5. Criar Containers
for ENV in prd qa tst; do
  az storage container create \
    --name terraform-state-$ENV \
    --account-name $STORAGE_ACCOUNT \
    --auth-mode login
done

# 6. Verificar
az storage container list \
  --account-name $STORAGE_ACCOUNT \
  --auth-mode login \
  --output table
```

**Checkpoint**: Você deve ver 3 containers criados: `terraform-state-prd`, `terraform-state-qa`, `terraform-state-tst`

---

### 1.2 - Criar Service Principals por Ambiente

Cada ambiente (PRD, QA, TST) precisa de seu próprio Service Principal com:

```bash
# PRD
az ad sp create-for-rbac --name sp-terraform-prd --role Contributor
# [IMPORTANTE] SALVAR EM SEGREDO: appId, password, tenant

### 1.2 - Criar Service Principals

```bash
# Get Subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Service Principal para PRD
echo "=== Criando SP para PRD ==="
az ad sp create-for-rbac \
  --name "sp-terraform-prd" \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --output json > sp-prd.json

cat sp-prd.json
#  SALVAR EM SEGREDO: appId, password, tenant

# Service Principal para QA
echo "=== Criando SP para QA ==="
az ad sp create-for-rbac \
  --name "sp-terraform-qa" \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --output json > sp-qa.json

cat sp-qa.json

# Service Principal para TST
echo "=== Criando SP para TST ==="
az ad sp create-for-rbac \
  --name "sp-terraform-tst" \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --output json > sp-tst.json

cat sp-tst.json

#  DELETAR OS ARQUIVOS JSON APÓS SALVAR AS CREDENCIAIS!
rm sp-*.json
```

** Anotar**:
```
PRD:
  client_id: _______________
  client_secret: _______________
  tenant_id: _______________
  subscription_id: _______________

QA:
  client_id: _______________
  client_secret: _______________
  tenant_id: _______________
  subscription_id: _______________

TST:
  client_id: _______________
  client_secret: _______________
  tenant_id: _______________
  subscription_id: _______________
```

### 1.3 - Dar Permissões de Storage aos SPs

```bash
# Para cada Service Principal, dar permissão de acesso ao Storage

# PRD
SP_PRD_ID=$(az ad sp list --display-name "sp-terraform-prd" --query [0].id -o tsv)
az role assignment create \
  --assignee $SP_PRD_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT/blobServices/default/containers/terraform-state-prd"

# QA
SP_QA_ID=$(az ad sp list --display-name "sp-terraform-qa" --query [0].id -o tsv)
az role assignment create \
  --assignee $SP_QA_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT/blobServices/default/containers/terraform-state-qa"

# TST
SP_TST_ID=$(az ad sp list --display-name "sp-terraform-tst" --query [0].id -o tsv)
az role assignment create \
  --assignee $SP_TST_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT/blobServices/default/containers/terraform-state-tst"
```

** Checkpoint**: Cada SP tem acesso apenas ao seu container específico

---

## 🐳 PARTE 2: Docker Image

### 2.1 - Build da Imagem (Multi-stage otimizada)

```bash
cd docker/

# Build
docker build -t jenkins-terraform-agent:1.0 .

# Verificar tamanho
docker images | grep jenkins-terraform-agent

# Testar
docker run -it --rm jenkins-terraform-agent:1.0 bash

# Dentro do container, testar:
git --version
az version
terraform version
tfsec --version
checkov --version
terraform-docs --version
python3 --version
java -version
```

**Melhorias implementadas**:
-  **Multi-stage build** - reduz tamanho da imagem final (~30-40%)
-  **--no-install-recommends** - remove pacotes desnecessários
-  **openjdk-17-jre-headless** - JRE ao invés de JDK completo
-  **Layers otimizados** - melhor uso de cache
-  **Validations comentadas** - remover após testar

** O que deletar depois**:
No Dockerfile, após confirmar que tudo funciona, **deletar** o bloco:
```dockerfile
# ==============================================================================
# VALIDATION SECTION - DELETE AFTER TESTING
...
# END VALIDATION SECTION
# ==============================================================================
```

Isso vai economizar mais espaço (remove echoes e verificações).

### 2.2 - Push para Registry

```bash
# Opção A: Docker Hub
docker tag jenkins-terraform-agent:1.0 seu-usuario/jenkins-terraform-agent:1.0
docker push seu-usuario/jenkins-terraform-agent:1.0

# Opção B: Azure Container Registry
az acr login --name myregistry
docker tag jenkins-terraform-agent:1.0 myregistry.azurecr.io/jenkins-terraform-agent:1.0
docker push <registry>/terraform-agent:1.0.0
```

**Checkpoint**: Imagem disponível no registry escolhido

---

## PARTE 3: Repositórios Git

# Opção C: GitLab Container Registry
docker login registry.gitlab.com
docker tag jenkins-terraform-agent:1.0 registry.gitlab.com/yourgroup/jenkins-terraform-agent:1.0
docker push registry.gitlab.com/yourgroup/jenkins-terraform-agent:1.0
```

** Checkpoint**: Imagem disponível no registry escolhido

---

## 🔀 PARTE 3: Repositórios Git

### Estratégia: 2 Repositórios Separados

**Por quê 2 repos?**
- Separação de responsabilidades
- Versionamento independente
- CI/CD focado

#### Repo 1: terraform-azure-project
- **Propósito**: Documentação, templates, pipelines, scripts
- **Versionamento**: SEM tags (evolução livre)
- **Uso**: Referência e setup

#### Repo 2: terraform-azure-modules
- **Propósito**: Módulos Terraform versionados
- **Versionamento**: Semantic Versioning (v1.0.0, v1.1.0, etc)
- **Uso**: Produção (referenciado em projetos)

### 3.1 - Criar Repositório terraform-azure-project

```bash
# No GitLab, criar repositório vazio: terraform-azure-project

# Local
cd /path/to/terraform-azure-project
git init
git remote add origin git@gitlab.com:yourgroup/terraform-azure-project.git
git add .
git commit -m "Initial commit: Documentation and templates"
git push -u origin main
```

### 3.2 - Criar Repositório terraform-azure-modules

```bash
# No GitLab, criar repositório vazio: terraform-azure-modules

# Preparar estrutura
mkdir terraform-azure-modules
cd terraform-azure-modules

# Copiar módulos
cp -r ../terraform-azure-project/terraform-modules modules/

# Criar README.md
cat > README.md <<EOF
# Terraform Azure Modules

Módulos Terraform versionados para Azure.

## Uso

\`\`\`hcl
module "vnet" {
  source = "git@gitlab.com:yourgroup/terraform-azure-modules.git//modules/vnet?ref=v1.0.0"
  
  vnet_name           = "my-vnet"
  location            = "West Europe"
  resource_group_name = "my-rg"
  address_space       = ["10.0.0.0/16"]
  
  tags = {
    Environment = "Production"
  }
}
\`\`\`

## Versões

Ver [CHANGELOG.md](CHANGELOG.md)
EOF

# Criar CHANGELOG.md
cat > CHANGELOG.md <<EOF
# Changelog

## [1.0.0] - $(date +%Y-%m-%d)
### Added
- Initial release
- Módulos: vnet, subnet, nsg, ssh, vm-linux, nsg-rules
- Validações completas
- Documentação com terraform-docs
EOF

# Commit e tag
git init
git add .
git commit -m "Initial commit: Terraform Azure modules v1.0.0"
git tag -a v1.0.0 -m "Release v1.0.0 - Initial production release"

# Push
git remote add origin git@gitlab.com:yourgroup/terraform-azure-modules.git
git push -u origin main
git push origin v1.0.0
```

**Checkpoint**: 2 repositórios criados e primeira tag v1.0.0 no modules repo

---

## PARTE 4: Jenkins Configuration
```

** Checkpoint**: 2 repositórios criados e primeira tag v1.0.0 no modules repo

---

## 🔄 PARTE 4: Jenkins Setup

### 4.1 - Configurar Credentials no Jenkins

```
Jenkins > Manage Jenkins > Credentials > System > Global credentials
```

Criar as seguintes credentials (tipo: Secret text):

**PRD**:
- ID: `azure-sp-prd-client-id` → valor do appId
- ID: `azure-sp-prd-client-secret` → valor do password
- ID: `azure-sp-prd-subscription-id` → subscription ID
- ID: `azure-sp-prd-tenant-id` → tenant ID

**QA**:
- ID: `azure-sp-qa-client-id`
- ID: `azure-sp-qa-client-secret`
- ID: `azure-sp-qa-subscription-id`
- ID: `azure-sp-qa-tenant-id`

**TST**:
- ID: `azure-sp-tst-client-id`
- ID: `azure-sp-tst-client-secret`
- ID: `azure-sp-tst-subscription-id`
- ID: `azure-sp-tst-tenant-id`

**Outros**:
- ID: `gitlab-token` → Personal Access Token do GitLab
- ID: `teams-webhook-url` → Webhook URL do Teams
- ID: `dynatrace-api-token` → API Token do Dynatrace
- ID: `dynatrace-api-url` → API URL do Dynatrace

### 4.2 - Configurar Docker Cloud

```
Jenkins > Manage Jenkins > Clouds > New cloud

Name: docker-agents
Type: Docker

Docker Host URI: unix:///var/run/docker.sock
Enabled: 

Docker Agent Template:
  Labels: terraform-azure-agent
  Name: terraform-azure-agent
  Docker Image: jenkins-terraform-agent:1.0  (ou seu registry)
  Remote File System Root: /home/jenkins
  Connect method: Attach Docker container
  User: jenkins
  Pull strategy: Pull once and update latest
```

### 4.3 - Criar Pipeline de Validação

```
Jenkins > New Item
Name: terraform-validation
Type: Pipeline

Pipeline script from SCM:
  SCM: Git
  Repository URL: git@gitlab.com:yourgroup/terraform-azure-modules.git
  Credentials: gitlab-token
  Branch: */main
  Script Path: pipelines/terraform-validation-pipeline.groovy
```

### 4.4 - Criar Pipeline de Deploy

```
Jenkins > New Item
Name: terraform-deploy
Type: Pipeline

Parameters:
  - ENVIRONMENT: Choice (prd, qa, tst)
  - PROJECT_NAME: String
  - ACTION: Choice (plan, apply, destroy)

Pipeline script from SCM:
  SCM: Git
  Repository URL: git@gitlab.com:yourgroup/terraform-azure-project.git
  Credentials: gitlab-token
  Branch: */main
  Script Path: pipelines/terraform-deploy-pipeline.groovy
```

** Checkpoint**: Jenkins configurado com Docker agent e 2 pipelines

---

## 💻 PARTE 5: Usar o Backend nos Projetos

### Configuração nos Projetos Terraform

**providers.tf**:
```hcl
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "terraform-backend-rg"
    storage_account_name = "terraformstatestorage"
    container_name       = "terraform-state-prd"  # ou qa, tst
    key                  = "power-bi/terraform.tfstate"  # nome do projeto
  }
}

provider "azurerm" {
  features {}
  # Credenciais vem das env vars:
  # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID
}
```

### Usando Módulos Versionados

**main.tf**:
```hcl
module "vnet" {
  source = "git@gitlab.com:yourgroup/terraform-azure-modules.git//modules/vnet?ref=v1.0.0"
  
  vnet_name           = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  
  tags = {
    Environment = var.environment
    Project     = "power-bi"  # ou digital-cabin, projeto-X, etc
    ManagedBy   = "Terraform"
  }
}

module "subnet" {
  source = "git@gitlab.com:yourgroup/terraform-azure-modules.git//modules/subnet?ref=v1.0.0"
  
  subnet_name          = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = module.vnet.vnet_name
  address_prefixes     = var.subnet_address_prefixes
}
```

### Deploy Manual (Teste)

```bash
# Exportar credenciais do ambiente desejado
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_SUBSCRIPTION_ID="..."
export ARM_TENANT_ID="..."

# Login Azure
az login --service-principal \
  -u $ARM_CLIENT_ID \
  -p $ARM_CLIENT_SECRET \
  --tenant $ARM_TENANT_ID

# Terraform
terraform init
terraform plan
terraform apply
```

** Checkpoint**: State file criado no Azure Storage

---

##  PARTE 6: Validação Final

### 6.1 - Verificar State no Azure

```bash
# Listar states
az storage blob list \
  --account-name terraformstatestorage \
  --container-name terraform-state-prd \
  --auth-mode login \
  --output table

# Ver conteúdo de um state
az storage blob download \
  --account-name terraformstatestorage \
  --container-name terraform-state-prd \
  --name "power-bi/terraform.tfstate" \
  --file /tmp/state.json \
  --auth-mode login

cat /tmp/state.json | jq '.version'
```

### 6.2 - Testar State Locking

```bash
# Terminal 1
terraform plan
# (deixar rodando...)

# Terminal 2
terraform plan
# Deve falhar com: Error acquiring the state lock
```

### 6.3 - Executar Pipeline no Jenkins

```
Jenkins > terraform-deploy > Build with Parameters

ENVIRONMENT: qa
PROJECT_NAME: power-bi  # ou digital-cabin, projeto-X
ACTION: plan

[Build]
```

Verificar:
-  Docker agent inicia
-  Checkout do código
-  Terraform init OK
-  Terraform plan OK
-  Notificação no Teams (se configurado)

**Nota**: Cada projeto (power-bi, digital-cabin, projeto-X) tem sua própria arquitetura Terraform específica

---

## 📚 Referências Rápidas

### Backend Config por Ambiente

```bash
# PRD
container_name = "terraform-state-prd"

# QA
container_name = "terraform-state-qa"

# TST
container_name = "terraform-state-tst"
```

### Versionamento de Módulos

```hcl
# Usar versão específica
?ref=v1.0.0

# Atualizar versão
?ref=v1.1.0
```

### Comandos Úteis

```bash
# Ver versões de módulos
git ls-remote --tags git@gitlab.com:yourgroup/terraform-azure-modules.git

# State locking force unlock (CUIDADO!)
terraform force-unlock LOCK_ID

# Download de state
terraform state pull > backup.tfstate

# Upload de state
terraform state push backup.tfstate

# Ver recursos no state
terraform state list

# Ver detalhes de recurso
terraform state show azurerm_virtual_network.this
```

---

## 🐛 Troubleshooting

### Problema: Docker image muito grande

**Solução**: Após validar funcionamento, deletar seção VALIDATION do Dockerfile e rebuild:
```bash
# Remover linhas 112-122 do Dockerfile (seção de verificação)
docker build -t jenkins-terraform-agent:1.0 .
```

### Problema: State lock não liberando

**Solução**:
```bash
# Aguardar 15 segundos (lock expira automaticamente)
sleep 20

# Ou force unlock (só se tiver certeza!)
terraform force-unlock LOCK_ID
```

### Problema: Permissão negada no Storage

**Solução**:
```bash
# Verificar permissões do SP
az role assignment list \
  --assignee $ARM_CLIENT_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/terraform-backend-rg"

# Adicionar permissão se necessário
az role assignment create \
  --assignee $ARM_CLIENT_ID \
  --role "Storage Blob Data Contributor" \
  --scope "..."
```

---

##  Checklist Final

Antes de considerar completo:

**Azure**:
- [ ] Storage Account criado
- [ ] 3 containers criados (prd, qa, tst)
- [ ] 3 Service Principals criados
- [ ] Permissões RBAC configuradas
- [ ] Versioning habilitado
- [ ] Soft delete habilitado

**Git**:
- [ ] terraform-azure-project criado
- [ ] terraform-azure-modules criado
- [ ] Tag v1.0.0 criada
- [ ] Branch protection configurada

**Jenkins**:
- [ ] Docker image buildada
- [ ] 12+ credentials cadastradas
- [ ] Docker cloud configurado
- [ ] 2 pipelines criadas

**Validação**:
- [ ] Deploy manual funcionou
- [ ] State no Azure Storage
- [ ] State locking OK
- [ ] Pipeline Jenkins OK

---

##  Notas Finais

**Docker Compose**: Removido - não necessário. Foi usado apenas para teste local inicial. Use `docker run` diretamente ou Jenkins.

**Multi-stage**: Implementado - reduz imagem de ~1.2GB para ~800MB.

**Backend**: 1 container por ambiente (prd/qa/tst) com projetos dentro como keys.

**Documentação**: Este documento será convertido em docs finais após conclusão e validação completa do setup.

---

**Última atualização**: 2025-12-04
**Status**: 🚧 Em construção
