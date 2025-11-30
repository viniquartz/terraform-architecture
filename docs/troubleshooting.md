# Guia de Troubleshooting - Terraform Azure

## 🔴 Problemas Críticos

### 1. State Lock Travado

**Sintomas**:
```
Error: Error acquiring the state lock
Lock Info:
  ID:        xxxxx-xxxxx-xxxxx
  Path:      container/path/terraform.tfstate
  Operation: OperationTypeApply
  Who:       user@hostname
  Version:   1.5.0
  Created:   2024-01-15 10:30:00
```

**Causas**:
- Pipeline interrompida abruptamente
- Timeout de rede durante operação
- Crash do Terraform

**Solução**:

```bash
# 1. Verificar se processo ainda está rodando
# Checar Jenkins/Azure portal

# 2. Se tem certeza que nada está rodando:
terraform force-unlock <LOCK_ID>

# 3. Se force-unlock não funcionar:
# Remover lock manualmente do storage
az storage blob delete \
  --account-name stterraformstate \
  --container-name tfstate \
  --name "project/env/terraform.tfstate.lock"

# 4. Tentar operação novamente
terraform plan
```

**Prevenção**:
- Nunca interromper pipelines manualmente
- Configurar timeouts adequados
- Usar `-lock-timeout=10m` em operações Terraform

---

### 2. State Corrompido ou Inconsistente

**Sintomas**:
```
Error: state snapshot was created by Terraform v1.6.0, which is newer than current v1.5.0
```
ou
```
Error: Provider produced inconsistent result after apply
```

**Soluções**:

**Caso 1: Versão incompatível**
```bash
# Upgrade do Terraform
brew upgrade terraform  # macOS
# ou
tfenv install 1.6.0 && tfenv use 1.6.0

# Verificar versão
terraform version
```

**Caso 2: State corrompido**
```bash
# 1. Baixar state atual
terraform state pull > terraform.tfstate.backup

# 2. Restaurar de versão anterior (Azure Storage Versioning)
az storage blob download \
  --account-name stterraformstate \
  --container-name tfstate \
  --name "project/env/terraform.tfstate" \
  --version-id <VERSION_ID> \
  --file terraform.tfstate.restored

# 3. Fazer push do state restaurado
terraform state push terraform.tfstate.restored

# 4. Verificar
terraform plan
```

**Caso 3: Recurso órfão no state**
```bash
# Listar recursos no state
terraform state list

# Remover recurso problemático
terraform state rm azurerm_resource.example

# Re-importar se necessário
terraform import azurerm_resource.example /subscriptions/.../resourceGroups/.../...
```

---

### 3. Drift Massivo em Produção

**Sintomas**:
- Pipeline de drift detection reportando muitas mudanças
- Plan mostra dezenas de alterações inesperadas

**Investigação**:
```bash
# 1. Ver o que mudou
terraform plan -detailed-exitcode > drift-report.txt

# 2. Buscar no Azure Activity Log quem fez mudanças
az monitor activity-log list \
  --resource-group <rg-name> \
  --start-time $(date -u -d '24 hours ago' '+%Y-%m-%dT%H:%M:%SZ') \
  --query "[].{Time:eventTimestamp, User:caller, Operation:operationName.localizedValue, Resource:resourceId}" \
  -o table

# 3. Comparar state com realidade
terraform show > current-state.txt
```

**Decisão**:

**Opção A: Mudanças foram intencionais (por emergência)**
```bash
# Atualizar código Terraform para refletir a realidade
# Fazer code review
# Commit e push
git add .
git commit -m "fix: sync with emergency changes in production"
git push

# Verificar que plan agora mostra 0 changes
terraform plan
```

**Opção B: Mudanças foram acidentais**
```bash
# CUIDADO: Isso irá reverter mudanças manuais!
# Coordenar com o time antes

# 1. Backup do state atual
terraform state pull > state-before-revert.json

# 2. Aplicar configuração Terraform
terraform apply

# 3. Validar recursos
./scripts/validation/validate-resources.sh
```

---

## ⚠️ Problemas Comuns

### 4. Erro de Permissão do Service Principal

**Sintomas**:
```
Error: authorization.RoleAssignmentsClient#Create: Failure responding to request:
StatusCode=403 -- Original Error: autorest/azure: Service returned an error.
Status=403 Code="AuthorizationFailed" Message="The client 'xxxx' with object id 'yyyy'
does not have authorization to perform action 'Microsoft.Authorization/roleAssignments/write'"
```

**Solução**:
```bash
# 1. Verificar roles atuais do SP
SP_ID=$(az ad sp list --display-name sp-terraform-production --query '[0].id' -o tsv)
az role assignment list --assignee $SP_ID --all -o table

# 2. Adicionar role necessária
az role assignment create \
  --assignee $SP_ID \
  --role "User Access Administrator" \
  --scope "/subscriptions/<subscription-id>"

# Roles comuns necessárias:
# - Contributor (básico)
# - User Access Administrator (para gerenciar IAM)
# - Storage Blob Data Contributor (para state)
# - Key Vault Administrator (para Key Vaults)
```

---

### 5. Timeout em Resources Lentos

**Sintomas**:
```
Error: waiting for creation of Virtual Machine "vm-example": timeout while waiting for state
```

**Solução**:
```hcl
# Adicionar timeouts no recurso
resource "azurerm_linux_virtual_machine" "example" {
  # ... outras configs ...
  
  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}
```

**Ou via provider**:
```hcl
provider "azurerm" {
  features {}
  
  # Aumentar timeout global
  skip_provider_registration = false
  
  # Para operações específicas
  client_timeouts {
    create = "60m"
  }
}
```

---

### 6. Erro de Conflito de Nomes

**Sintomas**:
```
Error: A resource with the ID "/subscriptions/.../resourceGroups/rg-example" already exists
```

**Causas**:
- Recurso foi criado manualmente
- Import não foi feito
- Naming collision

**Soluções**:

**Opção 1: Import do recurso**
```bash
terraform import azurerm_resource_group.example /subscriptions/.../resourceGroups/rg-example
```

**Opção 2: Remover recurso existente**
```bash
# CUIDADO: Isso deleta o recurso!
az group delete --name rg-example --yes
```

**Opção 3: Usar nome diferente**
```hcl
resource "azurerm_resource_group" "example" {
  name     = "rg-example-v2"  # Nome único
  location = "eastus"
}
```

---

### 7. Provider Cache Issues

**Sintomas**:
```
Error: Failed to query available provider packages
Error: Could not retrieve the list of available versions
```

**Solução**:
```bash
# 1. Limpar cache do Terraform
rm -rf .terraform
rm .terraform.lock.hcl

# 2. Re-inicializar
terraform init

# 3. Se continuar, limpar cache global
rm -rf ~/.terraform.d/plugin-cache

# 4. Upgrade de providers
terraform init -upgrade
```

---

## 🐛 Problemas de Pipeline

### 8. Pipeline Falha na Validação

**Sintomas**:
- Stage "Terraform Validate" falha
- Erros de sintaxe ou configuração

**Checklist**:
```bash
# 1. Validar localmente
terraform fmt -check
terraform validate

# 2. Verificar versões
terraform version
grep required_version *.tf

# 3. Verificar providers
terraform providers

# 4. Linting
tflint --init
tflint
```

**Erros comuns**:
- Variável não declarada
- Tipo incorreto
- Referência circular
- Provider não configurado

---

### 9. Security Scan Falha (TFSec/Checkov)

**Sintomas**:
```
Check: CKV_AZURE_35: "Ensure default network access rule for Storage Accounts is set to deny"
Result: FAILED
```

**Solução**:
```hcl
# Exemplo: Corrigir Security finding
resource "azurerm_storage_account" "example" {
  name                     = "stexample"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  
  # FIX: Adicionar configurações de segurança
  min_tls_version                 = "TLS1_2"
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false
  
  network_rules {
    default_action = "Deny"  # FIX
    ip_rules       = ["your-ip/32"]
    bypass         = ["AzureServices"]
  }
}
```

**Suprimir falso-positivo**:
```hcl
# Se o finding não se aplica ao seu caso
resource "azurerm_storage_account" "example" {
  #checkov:skip=CKV_AZURE_35: Storage account usado apenas internamente
  #tfsec:ignore:azure-storage-default-action-deny: Acesso público necessário para CDN
  
  # ... config ...
}
```

---

### 10. Aprovação Timeout

**Sintomas**:
- Pipeline aguardando aprovação
- Timeout após X horas

**Solução**:

**Imediato**:
1. Aprovar via Jenkins UI
2. Ou abortar e re-executar

**Permanente**:
```groovy
// Ajustar timeout em pipelines/terraform-deploy-pipeline.groovy
timeout(time: 8, unit: 'HOURS') {  // Aumentar se necessário
    input message: 'Approve deployment?'
}
```

**Notificações**:
- Verificar se Teams está recebendo notificações
- Verificar webhook do Teams
- Verificar lista de aprovadores

---

## 🔧 Problemas de Módulos

### 11. Módulo Não Encontrado

**Sintomas**:
```
Error: Module not found
Error: Failed to download module
```

**Checklist**:
```bash
# 1. Verificar URL do módulo
# Correto:
source = "git::https://gitlab.com/org/terraform-azure-modules.git//networking/vnet?ref=v1.0.0"

# 2. Verificar acesso ao repositório
git ls-remote https://gitlab.com/org/terraform-azure-modules.git

# 3. Verificar tag existe
git ls-remote --tags https://gitlab.com/org/terraform-azure-modules.git | grep v1.0.0

# 4. Limpar cache
rm -rf .terraform/modules
terraform init
```

---

### 12. Breaking Change em Módulo

**Sintomas**:
- Plan mostra replacement de recursos após atualizar versão do módulo

**Solução**:
```hcl
# NÃO fazer:
source = "git::...//module?ref=main"  # Versão instável

# SEMPRE usar tags:
source = "git::...//module?ref=v1.2.0"  # Versão específica

# Para atualizar:
# 1. Ler CHANGELOG do módulo
# 2. Testar em development primeiro
# 3. Verificar breaking changes
# 4. Ajustar código conforme necessário
# 5. Deploy gradual (dev -> test -> staging -> prod)
```

---

## 📊 Debugging Avançado

### 13. Habilitar Debug Logging

```bash
# Terraform debug
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log
terraform plan

# Azure CLI debug
az group list --debug

# Ver HTTP requests
export TF_LOG=TRACE
```

### 14. Analisar State

```bash
# Ver state completo
terraform show

# Ver recurso específico
terraform state show azurerm_resource_group.example

# Listar todos recursos
terraform state list

# Ver dependencies
terraform graph | dot -Tpng > graph.png
```

### 15. Comparar States

```bash
# Download de dois states
terraform state pull > state-current.json

# Após fazer mudanças
terraform state pull > state-after.json

# Comparar
diff state-current.json state-after.json
```

---

## 📞 Quando Escalar

### Escalar para Platform Team se:
- State corruption persistente
- Problema com módulo compartilhado
- Bug no provider

### Escalar para Security Team se:
- Credenciais comprometidas
- Violação de compliance
- Acesso não autorizado detectado

### Escalar para Arquiteto se:
- Decisão sobre mudança arquitetural
- Problema de design/escala
- Migração complexa

---

## 🔍 Ferramentas Úteis

```bash
# Validar todos arquivos .tf
find . -name "*.tf" -exec terraform fmt -check {} \;

# Buscar por padrões
grep -r "hard.*coded.*password" .

# Verificar custos (Infracost)
infracost breakdown --path .

# Security scan local
tfsec .
checkov -d .

# Documentação automática
terraform-docs markdown table . > README.md
```

---

**Última atualização**: 30 de Novembro de 2025  
**Mantido por**: DevOps Team
