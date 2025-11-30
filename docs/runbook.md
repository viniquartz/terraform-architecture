# Runbook Operacional - Terraform Azure

## 🚨 Procedimentos de Emergência

### 1. Rollback de Deployment

**Quando usar**: Deployment causou problemas em produção

```bash
# Opção 1: Via Jenkins
# Acesse a pipeline terraform-deploy-pipeline
# Configure os parâmetros:
PROJECT_NAME=<nome-do-projeto>
ENVIRONMENT=production
ACTION=destroy  # ou apply com versão anterior
GIT_BRANCH=<tag-anterior>

# Opção 2: Via Terraform direto (emergência)
cd /path/to/project
terraform workspace select production
terraform plan -destroy
# Após aprovação do time
terraform apply -destroy
```

### 2. State Corrompido

**Sintomas**: `Error acquiring the state lock`, `state snapshot was created by Terraform v...`

```bash
# 1. Verificar se há lock travado
az storage blob list \
  --account-name stterraformstate \
  --container-name tfstate \
  --prefix "project-name/production" \
  --query "[?name contains(@, '.tflock')]"

# 2. Remover lock manual (CUIDADO!)
# Certifique-se que nenhuma pipeline está rodando
terraform force-unlock <LOCK_ID>

# 3. Restaurar state de backup
# Backend tem versioning habilitado
az storage blob list \
  --account-name stterraformstate \
  --container-name tfstate \
  --prefix "project-name/production/terraform.tfstate" \
  --include v

# Baixar versão anterior
az storage blob download \
  --account-name stterraformstate \
  --container-name tfstate \
  --name "project-name/production/terraform.tfstate" \
  --version-id <VERSION_ID> \
  --file terraform.tfstate.backup
```

### 3. Drift Detectado Crítico

**Sintomas**: Alert da pipeline de drift detection

```bash
# 1. Verificar o drift
cd /path/to/project
terraform workspace select <environment>
terraform plan -detailed-exitcode

# Exitcode 2 = drift detectado

# 2. Analisar mudanças
terraform show

# 3. Opções:
# A) Importar mudanças para o código (se intencional)
terraform plan -out=plan.tfplan
# Revise o plano e atualize o código

# B) Reverter mudanças (se acidental)
terraform apply  # Isso revertará para o estado desejado
```

## 📋 Procedimentos Rotineiros

### Deploy de Novo Projeto

**Checklist**:

1. **Preparação**
   - [ ] Código Terraform criado e revisado
   - [ ] Módulos versionados (tags)
   - [ ] Backend configurado
   - [ ] Variables definidas para todos os ambientes
   - [ ] Code review aprovado
   - [ ] Merge na branch principal

2. **Deploy Development**
   ```bash
   # Jenkins: terraform-deploy-pipeline
   PROJECT_NAME=my-new-project
   ENVIRONMENT=development
   ACTION=apply
   GIT_BRANCH=main
   ```
   - [ ] Pipeline executada com sucesso
   - [ ] Validações passaram
   - [ ] Testes pós-deploy OK

3. **Deploy Testing**
   - [ ] Mesmos passos do development
   - [ ] Testes de integração realizados

4. **Deploy Staging**
   - [ ] Mesmos passos anteriores
   - [ ] Testes de carga realizados
   - [ ] Aprovação DevOps

5. **Deploy Production**
   - [ ] Change Request aprovado
   - [ ] Janela de manutenção agendada
   - [ ] Aprovações DevOps + Security
   - [ ] Plano de rollback pronto
   - [ ] Deploy executado
   - [ ] Validação pós-deploy
   - [ ] Monitoramento por 24h

### Criação de Novo Módulo

1. **Desenvolvimento**
   ```bash
   cd terraform-azure-modules
   mkdir -p category/module-name/{examples/complete,tests}
   
   # Criar arquivos base
   touch category/module-name/{main.tf,variables.tf,outputs.tf,versions.tf,README.md}
   touch category/module-name/examples/complete/main.tf
   ```

2. **Implementação**
   - Seguir padrão definido em `terraform-modules/README.md`
   - Adicionar validações nas variáveis
   - Documentar todas as inputs/outputs
   - Criar exemplo funcional
   - Escrever testes Terratest

3. **Validação**
   ```bash
   # Executar localmente
   cd category/module-name/examples/complete
   terraform init
   terraform plan
   terraform apply
   
   # Rodar testes
   cd ../tests
   go test -v -timeout 30m
   ```

4. **Review e Merge**
   - Criar Merge Request
   - Pipeline de validação deve passar
   - Code review por 2+ pessoas
   - Merge na main

5. **Release**
   ```bash
   git tag -a v1.0.0 -m "Initial release of module-name"
   git push origin v1.0.0
   ```

### Import de Recursos Legados

**Processo**:

1. **Análise**
   ```bash
   # Gerar comandos de import
   ./scripts/import/generate-import-commands.sh <resource-group-name>
   
   # Arquivos gerados:
   # - import-commands-<rg>.sh
   # - imported-resources-<rg>.tf
   ```

2. **Execução**
   ```bash
   # Criar diretório para o projeto
   mkdir -p projects/legacy-<name>
   cd projects/legacy-<name>
   
   # Copiar arquivos gerados
   cp ../../import-commands-<rg>.sh .
   cp ../../imported-resources-<rg>.tf main.tf
   
   # Configurar backend
   cat > backend.tf <<EOF
   terraform {
     backend "azurerm" {
       resource_group_name  = "rg-terraform-state-prod-eastus"
       storage_account_name = "stterraformstate"
       container_name       = "tfstate"
       key                  = "legacy-<name>/production/terraform.tfstate"
     }
   }
   EOF
   
   # Executar import
   terraform init
   chmod +x import-commands-<rg>.sh
   ./import-commands-<rg>.sh
   ```

3. **Refinamento**
   ```bash
   # Verificar estado
   terraform plan
   
   # Ajustar código até plan mostrar 0 changes
   # Refatorar para usar módulos
   ```

4. **Validação Final**
   - Code review
   - Pipeline de validação
   - Teste em non-prod primeiro

## 🔍 Troubleshooting

### Pipeline Falhou - Aprovação Timeout

**Causa**: Ninguém aprovou no tempo limite

**Solução**:
```bash
# Re-executar a pipeline
# Ou aumentar timeout em pipelines/terraform-deploy-pipeline.groovy:
timeout(time: 8, unit: 'HOURS')  # Ajustar conforme necessário
```

### Erro: "Error: Provider produced inconsistent result"

**Causa**: Bug no provider ou resource mal configurado

**Solução**:
```bash
# 1. Atualizar provider
terraform init -upgrade

# 2. Limpar cache
rm -rf .terraform
terraform init

# 3. Verificar se há recursos duplicados no state
terraform state list | grep <resource-name>

# 4. Se necessário, remover do state e re-importar
terraform state rm <resource-address>
terraform import <resource-address> <azure-resource-id>
```

### Erro: "Insufficient privileges to complete operation"

**Causa**: Service Principal sem permissões

**Solução**:
```bash
# Verificar roles do SP
SP_ID=$(az ad sp list --display-name sp-terraform-production --query '[0].id' -o tsv)
az role assignment list --assignee $SP_ID --all

# Adicionar role necessária
az role assignment create \
  --assignee $SP_ID \
  --role "Contributor" \
  --scope "/subscriptions/<subscription-id>"
```

### Drift em Recursos Sensíveis

**Recursos que não devem ter drift**:
- Networking (VNets, Subnets, NSGs)
- Security (Key Vaults, Managed Identities)
- Databases

**Processo**:
1. Investigar quem fez a mudança manual
2. Avaliar se mudança deve ser mantida
3. Se sim: atualizar código Terraform
4. Se não: reverter com `terraform apply`
5. Educar time sobre processo correto

## 📊 Monitoramento

### Métricas Críticas (Dynatrace)

**Alertar se**:
- `terraform.pipeline.duration` > 30 minutos
- `terraform.pipeline.failure_rate` > 10%
- `terraform.drift.detected` em production
- `terraform.security_scan.critical` > 0

### Logs Importantes

**Jenkins**:
- Console output das pipelines
- Filtrar por: `[ERROR]`, `[FAIL]`, `drift detected`

**Azure Activity Log**:
```bash
az monitor activity-log list \
  --resource-group <rg-name> \
  --start-time 2024-01-01T00:00:00Z \
  --query "[?contains(operationName.value, 'write') || contains(operationName.value, 'delete')]"
```

## 📞 Escalação

### Nível 1: DevOps Team
- Issues gerais de pipeline
- Deploys rotineiros
- Drift detection

### Nível 2: Platform Team
- Problemas com módulos
- State corruption
- Provider issues

### Nível 3: Security Team
- Violações de segurança
- Compliance issues
- Acesso a credenciais

### Nível 4: Arquiteto Cloud
- Decisões arquiteturais
- Mudanças estruturais
- Migração de projetos críticos

## 📅 Tarefas Agendadas

### Diária
- Revisar resultados da drift detection (4x ao dia)
- Verificar pipelines falhadas
- Aprovar MRs pendentes

### Semanal
- Revisar logs de audit
- Atualizar módulos (se necessário)
- Limpar workspaces temporários

### Mensal
- Review de custos Azure
- Atualização de documentação
- Audit de acessos e permissões
- Review de tags obrigatórias

### Trimestral
- Upgrade do Terraform version
- Upgrade dos providers
- Review completo da arquitetura
- Treinamento do time

## 🔐 Credenciais e Acessos

### Jenkins Credentials
- `azure-sp-*`: Service Principals por ambiente
- `azure-tenant-id`: Tenant ID
- `azure-subscription-id`: Subscription ID
- `teams-webhook-url`: Webhook do Teams
- `dynatrace-api-token`: Token da API Dynatrace

**Rotação**: A cada 90 dias

### Azure Storage (State)
- Acesso via Service Principal
- Backup automático (versioning habilitado)
- Soft delete: 30 dias

### Git Repositories
- SSH keys para cloning
- Personal Access Tokens para API

## 📝 Change Management

### Mudanças Normais
- Aprovação: DevOps Team
- Ambiente: development, testing, staging
- Execução: A qualquer momento

### Mudanças em Produção
- Aprovação: DevOps + Security Teams
- Change Request: Obrigatório
- Janela: Horário comercial (exceto emergência)
- Rollback plan: Obrigatório

### Mudanças de Emergência
- Aprovação: Verbal + documentação posterior
- Execução: Imediata
- Post-mortem: Obrigatório em 48h

---

**Última atualização**: 30 de Novembro de 2025  
**Mantido por**: DevOps Team  
**Próxima revisão**: Fevereiro 2026
