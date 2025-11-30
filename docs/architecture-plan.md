# Plano de Arquitetura Terraform para Azure

**Versão:** 3.0  
**Data:** 30 de Novembro de 2025  
**Autor:** Arquiteto Cloud Azure  
**Status:** Aprovado

---

## 📋 Sumário Executivo

Este documento apresenta o plano completo de arquitetura para implementação de Terraform como solução de Infrastructure as Code (IaC) no Azure, seguindo as melhores práticas do mercado.

### Objetivos

- Modernizar a infraestrutura Azure usando IaC
- Padronizar deployments entre ambientes
- Garantir segurança, auditoria e compliance
- Facilitar rollback e disaster recovery
- Reduzir erros humanos e tempo de deploy
- Implementar GitOps workflow completo

### Abordagem

- **Foco inicial**: Novos projetos (quick wins)
- **Fase 2**: Migração gradual de recursos legados
- **Timeline**: 20 semanas
- **Risco**: Médio (mitigado por phasing approach)

---

## 🏗️ Visão Geral da Arquitetura

### Componentes Principais

```
┌─────────────┐
│   GitLab    │  ← Source Control
└──────┬──────┘
       │ Webhook
       ↓
┌─────────────┐
│   Jenkins   │  ← CI/CD Orchestration
│  (Shared    │
│   Library)  │
└──────┬──────┘
       │
       ├─→ Pipeline 1: Deploy
       ├─→ Pipeline 2: Validation
       ├─→ Pipeline 3: Drift Detection
       └─→ Pipeline 4: Module Validation
       
       ↓
┌─────────────┐
│   Azure     │  ← Cloud Provider
│  Resources  │
└─────────────┘
```

### Stack Tecnológica

| Componente | Tecnologia | Versão |
|------------|-----------|--------|
| IaC Tool | Terraform | >= 1.5.0 |
| Cloud Provider | Azure | N/A |
| CI/CD | Jenkins | >= 2.400 |
| Repository | GitLab | N/A |
| State Backend | Azure Storage | N/A |
| Notifications | Microsoft Teams | Webhook API |
| Observability | Dynatrace | API v2 |
| Security Scan | TFSec + Checkov | Latest |

---

## 📁 Estrutura do Repositório

### Organização

O projeto está organizado da seguinte forma:

```
terraform-azure-project/
├── README.md                          # Documentação principal
├── .gitignore                         # Arquivos ignorados
├── docs/                              # Documentação completa
│   ├── architecture-plan.md           # Este documento
│   ├── deployment-guide.md            # Guia de deployment
│   ├── runbook.md                     # Runbook operacional
│   └── troubleshooting.md             # Solução de problemas
├── pipelines/                         # Jenkins Shared Library
│   ├── README.md
│   ├── terraform-deploy-pipeline.groovy
│   ├── terraform-validation-pipeline.groovy
│   ├── terraform-drift-detection-pipeline.groovy
│   ├── terraform-modules-validation-pipeline.groovy
│   ├── sendTeamsNotification.groovy
│   └── sendDynatraceEvent.groovy
├── scripts/                           # Scripts auxiliares
│   ├── setup/
│   │   ├── configure-azure-backend.sh
│   │   └── create-service-principals.sh
│   ├── import/
│   │   └── generate-import-commands.sh
│   ├── validation/
│   └── utilities/
├── terraform-modules/                 # Guia para módulos (repo separado)
│   └── README.md
└── examples/                          # Templates e exemplos
    ├── new-project/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── terraform.tfvars.example
    └── module-usage/
```

---

## 🔄 Pipelines Centralizadas

### Estratégia: 4 Pipelines Parametrizadas

Optamos por **4 pipelines centralizadas** em vez de pipeline por projeto, pelos seguintes motivos:

**Vantagens:**
- ✅ Manutenção centralizada (1 lugar para updates)
- ✅ Garantia de padronização
- ✅ Métricas unificadas
- ✅ Redução de código duplicado
- ✅ Onboarding mais rápido

**Desvantagens mitigadas:**
- ⚠️ Complexidade inicial (mitigado por documentação)
- ⚠️ Flexibilidade (mitigado por parametrização)

### Pipeline 1: Terraform Deploy

**Propósito**: Deploy e destroy de projetos Terraform

**Código**: [`pipelines/terraform-deploy-pipeline.groovy`](../pipelines/terraform-deploy-pipeline.groovy)

**Parâmetros**:
- `PROJECT_NAME`: Nome do projeto
- `ENVIRONMENT`: development | testing | staging | production
- `ACTION`: apply | destroy
- `GIT_BRANCH`: Branch ou tag a ser deployada

**Stages**:
1. Initialize
2. Checkout
3. Terraform Validate
4. Security Scan (TFSec + Checkov)
5. Terraform Plan
6. Approval (multi-level)
7. Terraform Apply/Destroy
8. Post-Deployment Tests
9. Notifications

**Aprovações**:

| Ambiente | Aprovação 1 | Aprovação 2 | Timeout |
|----------|-------------|-------------|---------|
| development | DevOps Team | - | 2h |
| testing | DevOps Team | - | 2h |
| staging | DevOps Team | - | 4h |
| **production** | **DevOps Team** | **Security Team** | **4h (apply)<br>8h (destroy)** |

**Integrações**:
- Microsoft Teams: Notificação em cada stage
- Dynatrace: Métricas de duração e status
- GitLab: Commit status updates

### Pipeline 2: Terraform Validation

**Propósito**: Validação automática em Merge Requests

**Código**: [`pipelines/terraform-validation-pipeline.groovy`](../pipelines/terraform-validation-pipeline.groovy)

**Trigger**: Webhook do GitLab em Merge Requests

**Execução**:
- Valida código em paralelo para todos os 4 ambientes
- Atualiza status do commit no GitLab
- Comenta no MR com resultados
- Block merge se validação falhar

**Stages**:
1. Checkout MR branch
2. Validate em paralelo (4 envs)
3. Report results

### Pipeline 3: Drift Detection

**Propósito**: Detecção automática de drift (mudanças manuais)

**Código**: [`pipelines/terraform-drift-detection-pipeline.groovy`](../pipelines/terraform-drift-detection-pipeline.groovy)

**Trigger**: Cron job (a cada 4 horas)

**Funcionamento**:
- Loop por todos os projetos e ambientes
- Executa `terraform plan -detailed-exitcode`
- Exit code 2 = drift detectado
- Notifica apenas se drift encontrado
- Dashboard no Dynatrace

**Alertas**:
- Teams: Mensagem com detalhes do drift
- Dynatrace: Custom event `terraform.drift.detected`

### Pipeline 4: Module Validation

**Propósito**: Quality gate para módulos Terraform

**Código**: [`pipelines/terraform-modules-validation-pipeline.groovy`](../pipelines/terraform-modules-validation-pipeline.groovy)

**Trigger**: Push/MR no repositório de módulos

**Validações**:
1. Detecção inteligente de módulos alterados
2. Terraform format check
3. Terraform validate
4. README.md obrigatório
5. Security scan (TFSec + Checkov)
6. Testes Terratest
7. Validação de exemplos
8. Geração de catálogo de módulos

**Critérios de Aprovação**:
- ✅ Todas as validações passam
- ✅ Security scan sem issues críticos
- ✅ Testes passam (se existirem)
- ✅ Documentação presente

---

## 🔔 Integrações

### Microsoft Teams

**Implementação**: [`pipelines/sendTeamsNotification.groovy`](../pipelines/sendTeamsNotification.groovy)

**Configuração**:
1. Criar Incoming Webhook no canal Teams
2. Adicionar URL no Jenkins credentials (`teams-webhook-url`)
3. Pipeline usa automaticamente

**Formato das Mensagens**:
- MessageCard adaptativo
- Cor por status (verde/vermelho/amarelo)
- Botões de ação (View Build)
- Facts: Projeto, Ambiente, Usuário, Duração
- Logs de erro (em caso de falha)

**Eventos Notificados**:
- Início de deploy
- Aguardando aprovação
- Aprovação concedida/negada
- Apply/Destroy completado
- Falhas
- Drift detectado

### Dynatrace

**Implementação**: [`pipelines/sendDynatraceEvent.groovy`](../pipelines/sendDynatraceEvent.groovy)

**Configuração**:
1. Gerar API token no Dynatrace
2. Adicionar no Jenkins credentials (`dynatrace-api-token`)
3. Configurar `DYNATRACE_TENANT_URL`

**Métricas Enviadas**:

```
terraform.pipeline.duration
  - Tags: project, environment, action
  - Unidade: milliseconds

terraform.pipeline.status
  - Tags: project, environment, status
  - Valor: 1 (success) ou 0 (failure)

terraform.resources.count
  - Tags: project, environment
  - Valor: número de recursos gerenciados

terraform.drift.detected
  - Tags: project, environment
  - Evento custom
```

**Dashboards Sugeridos**:
- Pipeline success rate por projeto
- Duração média por ambiente
- Drift detection timeline
- Top projetos por número de recursos

---

## 🗄️ State Management

### Backend: Azure Storage

**Configuração**: Script [`scripts/setup/configure-azure-backend.sh`](../scripts/setup/configure-azure-backend.sh)

**Características**:
- Storage Account com GRS (Geo-Redundant)
- Soft delete habilitado (30 dias)
- Versioning habilitado
- Acesso via Service Principal
- State locking via Azure Blob Lease

**Estrutura de State**:

```
tfstate/
├── project-a/
│   ├── development/
│   │   └── terraform.tfstate
│   ├── testing/
│   │   └── terraform.tfstate
│   ├── staging/
│   │   └── terraform.tfstate
│   └── production/
│       └── terraform.tfstate
├── project-b/
│   └── ...
└── modules/
    └── validation/
        └── terraform.tfstate
```

**Segurança**:
- Encryption at rest (Azure SSE)
- Encryption in transit (HTTPS)
- RBAC: Service Principal apenas
- Network rules: Allow Azure Services
- Audit logging habilitado

---

## 🧩 Módulos Terraform

### Estratégia: Monorepo

**Decisão**: Utilizar **monorepo** para módulos Terraform

**Repositório**: `terraform-azure-modules` (separado do projeto principal)

**Justificativa**:

| Critério | Monorepo | Multi-repo |
|----------|----------|------------|
| Versionamento | Git tags unificadas | ✅ Por módulo |
| Manutenção | ✅ Centralizada | Fragmentada |
| Descoberta | ✅ Fácil | Difícil |
| CI/CD | ✅ 1 pipeline | N pipelines |
| Cross-module changes | ✅ Atomic commits | Múltiplos PRs |
| Onboarding | ✅ 1 repo para clonar | N repos |

**Estrutura Sugerida**: Ver [`terraform-modules/README.md`](../terraform-modules/README.md)

### Categorias de Módulos

```
terraform-azure-modules/
├── networking/
│   ├── virtual-network/
│   ├── subnet/
│   ├── nsg/
│   └── application-gateway/
├── compute/
│   ├── virtual-machine/
│   ├── vmss/
│   └── aks/
├── storage/
│   ├── storage-account/
│   └── file-share/
├── database/
│   ├── sql-database/
│   ├── postgresql/
│   └── cosmos-db/
├── security/
│   ├── key-vault/
│   └── private-endpoint/
└── monitoring/
    ├── log-analytics/
    └── application-insights/
```

### Versionamento de Módulos

**Semantic Versioning**:
- `v1.0.0` - Major (breaking changes)
- `v1.1.0` - Minor (new features)
- `v1.1.1` - Patch (bug fixes)

**Uso**:
```hcl
module "network" {
  source = "git::https://gitlab.com/org/terraform-azure-modules.git//networking/virtual-network?ref=v1.0.0"
  
  name                = "vnet-example"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]
}
```

**Boas Práticas**:
- ✅ Sempre usar tags (nunca `ref=main`)
- ✅ Testar updates em non-prod primeiro
- ✅ Ler CHANGELOG antes de atualizar
- ✅ Pin versions em production
- ✅ CI/CD valida compatibilidade

---

## 🔐 Segurança

### Service Principals

**Script de criação**: [`scripts/setup/create-service-principals.sh`](../scripts/setup/create-service-principals.sh)

**Estratégia**: 1 Service Principal por ambiente

| Ambiente | Service Principal | Roles |
|----------|------------------|-------|
| development | sp-terraform-development | Contributor |
| testing | sp-terraform-testing | Contributor |
| staging | sp-terraform-staging | Contributor |
| production | sp-terraform-production | Contributor<br>Key Vault Administrator |

**Rotação de Credenciais**: A cada 90 dias

**Armazenamento**:
- Jenkins Credentials (encriptado)
- Azure Key Vault (backup)
- Documentação de emergência (cofre físico)

### Security Scanning

**Ferramentas**:
- **TFSec**: Análise estática especializada em Terraform
- **Checkov**: Policy-as-code com 1000+ checks

**Execução**:
- Em todas as pipelines (deploy e módulos)
- Block na presença de issues críticos
- Warning para médios/baixos

**Remediação**:
```hcl
# Suprimir falso-positivo (com justificativa)
resource "azurerm_storage_account" "example" {
  #checkov:skip=CKV_AZURE_35: Storage usado apenas internamente
  #tfsec:ignore:azure-storage-default-action-deny: CDN requer acesso público
  
  # ...
}
```

### Network Security

**Princípios**:
- Default deny em NSGs
- Service endpoints para PaaS
- Private endpoints para recursos críticos
- HTTPS only para storage
- TLS 1.2 mínimo

**Implementação**:
- Módulos já incluem defaults seguros
- Security scan valida compliance
- Revisão por Security Team em prod

### Secrets Management

**NÃO comitar**:
- ❌ Credentials
- ❌ API keys
- ❌ Certificates
- ❌ `.tfvars` com valores sensíveis

**Usar**:
- ✅ Azure Key Vault para secrets
- ✅ Jenkins Credentials para CI/CD
- ✅ Environment variables
- ✅ Terraform sensitive variables

```hcl
variable "admin_password" {
  type      = string
  sensitive = true  # Não aparece em logs
}
```

---

## 🎯 Convenções e Padrões

### Naming Convention

**Formato geral**: `<resource-type>-<workload>-<environment>-<region>-<instance>`

**Exemplos**:

| Recurso | Nome | Observação |
|---------|------|------------|
| Resource Group | `rg-webapp-prod-eastus` | Abreviações Azure |
| Virtual Network | `vnet-webapp-prod-eastus` | Lowercase, hífens |
| Storage Account | `stwebappprodeastus` | Sem hífens (limitação Azure) |
| Virtual Machine | `vm-webapp-prod-eastus-01` | Número para múltiplas instâncias |
| Key Vault | `kv-webapp-prod-eastus` | Máximo 24 caracteres |
| AKS Cluster | `aks-webapp-prod-eastus` | |

**Ambientes**:
- `dev` ou `development`
- `test` ou `testing`
- `stg` ou `staging`
- `prod` ou `production`

**Regiões** (abreviações):
- `eastus` - East US
- `eastus2` - East US 2
- `westus` - West US
- `brazilsouth` - Brazil South

### Tagging Strategy

**Tags Obrigatórias**:

```hcl
tags = {
  Environment  = "production"           # Obrigatória
  ManagedBy    = "Terraform"            # Obrigatória
  Project      = "web-application"      # Obrigatória
  CostCenter   = "IT-Infrastructure"    # Obrigatória
  Owner        = "devops@company.com"   # Obrigatória
  Criticality  = "High"                 # Opcional
  Compliance   = "PCI-DSS"              # Opcional
  BackupPolicy = "Daily"                # Opcional
}
```

**Validação**:
- Pipeline valida presença de tags obrigatórias
- Azure Policy reforça compliance
- Cost management usa tags para reporting

### Code Style

**Terraform**:
```hcl
# Usar terraform fmt sempre
terraform fmt -recursive

# Organização de arquivos
main.tf           # Recursos principais
variables.tf      # Variáveis de entrada
outputs.tf        # Outputs
versions.tf       # Versões de providers
backend.tf        # Configuração de backend (opcional)
terraform.tfvars  # Valores (não comitar se sensível)
```

**Convenções**:
- Lowercase para resources
- Snake_case para nomes
- Comentários em português nos `.tf`
- Documentação em português
- Código em inglês
- Mínimo 3 níveis de bloco: resource, module, data

---

## 📋 Workflow GitOps

### Branching Strategy

```
main (protected)
  ↑
  ├── feature/add-module-storage
  ├── feature/new-project-webapp
  ├── fix/nsg-rules
  └── hotfix/prod-issue
```

**Regras**:
- `main` é protegida (force push disabled)
- Merge apenas via Merge Request
- Require approvals (2+ reviewers)
- Pipeline de validação deve passar
- Squash commits on merge

### Desenvolvimento

**Fluxo**:

1. **Criar branch**
   ```bash
   git checkout -b feature/new-module
   ```

2. **Desenvolver localmente**
   ```bash
   # Desenvolver código
   terraform fmt -recursive
   terraform validate
   
   # Validar security
   tfsec .
   checkov -d .
   
   # Testar localmente
   terraform plan
   ```

3. **Commit e Push**
   ```bash
   git add .
   git commit -m "feat: add storage account module"
   git push origin feature/new-module
   ```

4. **Criar Merge Request**
   - Pipeline de validação executa automaticamente
   - Reviewers são notificados
   - GitLab mostra status da validação

5. **Code Review**
   - Mínimo 2 aprovações
   - Validação de segurança
   - Verificação de testes

6. **Merge**
   - Squash commits
   - Delete branch automaticamente

### Deployment

**Development/Testing**:
- Deploy automático após merge (opcional)
- Ou manual via Jenkins

**Staging**:
- Deploy manual via Jenkins
- Aprovação DevOps Team

**Production**:
- Deploy manual via Jenkins
- Change Request obrigatório
- Aprovação DevOps + Security
- Janela de manutenção agendada

---

## 📊 Monitoramento e Observabilidade

### Métricas Chave (KPIs)

| Métrica | Target | Alerta |
|---------|--------|--------|
| Pipeline Success Rate | > 95% | < 90% |
| Deploy Duration (avg) | < 15 min | > 30 min |
| Drift Detection Rate | 0% | > 5% |
| Security Scan Pass Rate | 100% | < 100% |
| MTTR (Mean Time to Repair) | < 1h | > 4h |
| Change Failure Rate | < 5% | > 10% |

### Dashboards Dynatrace

**Dashboard 1: Pipeline Overview**
- Total pipelines executed (por dia/semana)
- Success rate timeline
- Duração média por tipo de pipeline
- Top 10 projetos por execuções

**Dashboard 2: Deployment Health**
- Deploys por ambiente
- Rollback rate
- Approval time (média)
- Failed deployments por projeto

**Dashboard 3: Drift Detection**
- Drift events timeline
- Recursos com drift (lista)
- Ambientes com mais drift
- Tempo até remediação

**Dashboard 4: Security**
- Security findings por severidade
- Top vulnerabilities
- Compliance score
- Remediation time

### Alertas

**Críticos** (24/7 escalation):
- Pipeline failure em production
- Drift detection em production
- Security finding crítico
- State lock por > 1h

**Warnings** (horário comercial):
- Pipeline duration > 30min
- Drift em non-prod
- Security finding médio
- Approval timeout próximo

---

## 🚀 Plano de Implementação

### Fase 1: Fundação (Semanas 1-4)

**Objetivo**: Preparar infraestrutura base

**Tarefas**:

**Semana 1-2**:
- [ ] Configurar Azure Storage backend
- [ ] Criar Service Principals
- [ ] Configurar Jenkins Shared Library
- [ ] Setup GitLab repositories
- [ ] Documentar processos

**Semana 3-4**:
- [ ] Desenvolver módulos essenciais (networking, compute, storage)
- [ ] Criar exemplos e testes
- [ ] Configurar security scanning
- [ ] Setup Teams/Dynatrace integrações
- [ ] Treinar equipe

**Entregáveis**:
- ✅ Backend configurado
- ✅ 4 pipelines funcionais
- ✅ 5-10 módulos core
- ✅ Documentação completa

### Fase 2: Novos Projetos (Semanas 5-8)

**Objetivo**: Implementar Terraform em projetos novos

**Estratégia**: Quick wins

**Projetos piloto** (2-3 projetos):
- Complexidade baixa/média
- Não críticos
- Equipe colaborativa

**Atividades**:
- Desenvolver código Terraform usando módulos
- Deploy em development
- Testes e validação
- Deploy em testing/staging
- Code review e ajustes
- Deploy em production (com acompanhamento)

**Aprendizados**:
- Validar módulos em cenários reais
- Identificar gaps na documentação
- Ajustar processos conforme necessário
- Coletar feedback do time

**Entregáveis**:
- ✅ 2-3 projetos em production com Terraform
- ✅ Lições aprendidas documentadas
- ✅ Módulos ajustados baseado em feedback
- ✅ Processos refinados

### Fase 3: Expansão (Semanas 9-12)

**Objetivo**: Escalar para mais projetos novos

**Atividades**:
- Onboarding de mais projetos (5-10)
- Desenvolvimento de módulos adicionais
- Otimização de pipelines
- Automação de tarefas repetitivas
- Training adicional

**Entregáveis**:
- ✅ 10-15 projetos usando Terraform
- ✅ 20+ módulos disponíveis
- ✅ Self-service para novos projetos
- ✅ Documentação expandida

### Fase 4: Migração Legado (Semanas 13-20)

**Objetivo**: Migrar recursos existentes para Terraform

**Abordagem**: Gradual e priorizada

**Priorização**:

| Prioridade | Critérios | Estratégia |
|------------|-----------|------------|
| Alta | Mudam frequentemente<br>Múltiplos ambientes | Import primeiro |
| Média | Relativamente estáveis<br>Críticos | Import com cuidado |
| Baixa | Legado sem mudanças<br>Deprecation planejada | Deixar para depois |

**Processo de Import**:

1. **Inventário** (Semana 13)
   - Listar todos recursos Azure
   - Classificar por criticidade
   - Identificar dependências
   - Priorizar

2. **Import Piloto** (Semana 14-15)
   - Escolher 1 projeto de baixo risco
   - Usar script de import automatizado
   - Validar state vs realidade
   - Refatorar código para usar módulos
   - Testar em non-prod

3. **Import em Lote** (Semana 16-19)
   - Processar projetos priorizados
   - 2-3 projetos por semana
   - Sempre testar antes de prod
   - Documentar issues encontrados

4. **Validação Final** (Semana 20)
   - Verificar todos recursos migrados
   - Executar drift detection
   - Validar backups de state
   - Treinar times de produtos

**Scripts**:
- [`scripts/import/generate-import-commands.sh`](../scripts/import/generate-import-commands.sh) - Gera comandos de import

**Entregáveis**:
- ✅ 70-80% dos recursos sob Terraform
- ✅ Plano para 20% restantes
- ✅ Drift detection funcionando
- ✅ Equipe autônoma

### Fase 5: Otimização (Contínuo)

**Objetivo**: Melhorar continuamente

**Atividades**:
- Refatoração de código Terraform
- Otimização de módulos
- Melhoria de pipelines
- Atualização de dependências
- Training contínuo
- Review de processos

**Métricas de Sucesso**:
- Deploy time reduzido
- Zero drift em production
- Alta satisfação do time
- Redução de incidentes

---

## 📈 Métricas de Sucesso

### Mês 1 (Fase 1)

- [x] Backend configurado
- [x] 4 pipelines funcionais
- [x] 5 módulos core criados
- [x] Equipe treinada

### Mês 2 (Fase 2)

- [ ] 3 projetos novos usando Terraform
- [ ] Zero incidentes relacionados a Terraform
- [ ] Pipeline success rate > 90%
- [ ] 10 módulos disponíveis

### Mês 3 (Fase 3)

- [ ] 15 projetos usando Terraform
- [ ] Self-service habilitado
- [ ] 20 módulos disponíveis
- [ ] Deploy time < 20 min (média)

### Mês 4-5 (Fase 4)

- [ ] 50% recursos legados migrados
- [ ] Drift detection < 1%
- [ ] MTTR < 2h
- [ ] Zero incidentes críticos

### Mês 6+ (Fase 5)

- [ ] 80% recursos sob Terraform
- [ ] Deploy time < 15 min
- [ ] Pipeline success rate > 95%
- [ ] Drift detection = 0%
- [ ] Team satisfaction > 4/5

---

## 🎓 Training e Documentação

### Documentação Disponível

| Documento | Público | Localização |
|-----------|---------|-------------|
| Architecture Plan | Todos | `docs/architecture-plan.md` |
| Deployment Guide | DevOps | `docs/deployment-guide.md` |
| Runbook | Ops Team | `docs/runbook.md` |
| Troubleshooting | Todos | `docs/troubleshooting.md` |
| Pipeline README | DevOps | `pipelines/README.md` |
| Modules Guide | Developers | `terraform-modules/README.md` |
| Examples | Developers | `examples/` |

### Training Plan

**Nível 1: Básico** (4h)
- O que é Terraform
- Conceitos: Resources, Modules, State
- Workflow GitOps
- Como usar pipelines
- Demo prática

**Nível 2: Intermediário** (8h)
- Desenvolver módulos
- Testes com Terratest
- Debugging
- Import de recursos
- Security best practices

**Nível 3: Avançado** (16h)
- Arquitetura avançada
- State management profundo
- Performance tuning
- Disaster recovery
- CI/CD customization

---

## 🔄 Ciclo de Vida

### Daily Operations

**Responsabilidades DevOps Team**:
- Aprovar deploys em development/testing/staging
- Revisar drift detection reports
- Responder a alertas de pipelines
- Code review de Merge Requests
- Support a desenvolvedores

**Responsabilidades Security Team**:
- Aprovar deploys em production
- Revisar security scan findings
- Audit de permissões
- Compliance validation

**Responsabilidades Platform Team**:
- Manutenção de módulos
- Updates de pipelines
- Performance monitoring
- Capacity planning

### Maintenance Windows

**Mensal**:
- Terraform version update (se necessário)
- Provider updates
- Module updates
- Security patches

**Trimestral**:
- Review completo de arquitetura
- Audit de custos
- Process improvement
- Team retrospective

---

## 🚨 Disaster Recovery

### Backup Strategy

**State Files**:
- Versioning habilitado no Azure Storage
- Soft delete: 30 dias
- GRS replication (Geo-Redundant)
- Manual backup semanal (opcional)

**Código**:
- GitLab com backup diário
- Mirror em repositório secundário (opcional)
- Tags para releases importantes

**Credenciais**:
- Service Principals documentados
- Backup em Azure Key Vault
- Procedimento de rotação documentado

### Recovery Procedures

**Cenário 1: State corrompido**
```bash
# Restaurar versão anterior
az storage blob download \
  --version-id <VERSION_ID> \
  --file terraform.tfstate.restored

terraform state push terraform.tfstate.restored
```

**Cenário 2: GitLab indisponível**
```bash
# Usar mirror (se configurado)
git remote add mirror https://backup-gitlab.com/org/repo.git
git pull mirror main
```

**Cenário 3: Credenciais comprometidas**
```bash
# Rodar script de rotação
./scripts/setup/create-service-principals.sh

# Atualizar Jenkins credentials
# Testar com deploy em development
```

**Cenário 4: Azure region down**
- State está em GRS (outra região)
- Código está no GitLab (multi-AZ)
- Failover para região secundária

**RTO/RPO**:
- RTO (Recovery Time Objective): 4 horas
- RPO (Recovery Point Objective): 1 hora

---

## 💰 Custos Estimados

### Infraestrutura

| Item | Custo Mensal (USD) |
|------|--------------------|
| Azure Storage (State) | $5-10 |
| Service Principals | $0 (free) |
| Jenkins (self-hosted) | $100-200 (VM) |
| Dynatrace | $100-500 (conforme uso) |
| **Total** | **$205-710** |

### Esforço (Horas)

| Fase | Horas | Custo Estimado |
|------|-------|----------------|
| Fase 1: Fundação | 160h | $16,000 |
| Fase 2: Novos Projetos | 120h | $12,000 |
| Fase 3: Expansão | 160h | $16,000 |
| Fase 4: Migração | 240h | $24,000 |
| **Total** | **680h** | **$68,000** |

_Assumindo rate de $100/hora_

### ROI Esperado

**Ganhos** (anual):
- Redução de downtime: $50,000
- Economia de tempo (deploy manual): $80,000
- Redução de erros: $30,000
- **Total**: $160,000/ano

**Payback Period**: ~5 meses

---

## 📞 Suporte e Contatos

### Equipe

| Papel | Responsável | Contato |
|-------|-------------|---------|
| Arquiteto Cloud | [Nome] | arquiteto@company.com |
| DevOps Lead | [Nome] | devops-lead@company.com |
| Security Lead | [Nome] | security@company.com |
| Platform Lead | [Nome] | platform@company.com |

### Canais

- **Teams**: #terraform-azure
- **Email**: devops-team@company.com
- **On-call**: Via PagerDuty
- **GitLab Issues**: Para bugs e features
- **Confluence**: Wiki adicional

### Escalation

```
Nível 1: DevOps Team
   ↓ (se não resolvido em 2h)
Nível 2: Platform Team
   ↓ (se não resolvido em 4h)
Nível 3: Arquiteto + Management
```

---

## 🔍 Referências

### Documentação Oficial

- [Terraform Documentation](https://www.terraform.io/docs)
- [Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Azure Naming Convention](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)

### Ferramentas

- [TFSec](https://github.com/aquasecurity/tfsec)
- [Checkov](https://www.checkov.io/)
- [Terratest](https://terratest.gruntwork.io/)
- [Terraform Docs](https://terraform-docs.io/)
- [TFLint](https://github.com/terraform-linters/tflint)

### Comunidade

- [HashiCorp Discuss](https://discuss.hashicorp.com/)
- [r/Terraform](https://www.reddit.com/r/Terraform/)
- [Azure Terraform Samples](https://github.com/Azure/terraform)

---

## 📝 Changelog

| Versão | Data | Mudanças |
|--------|------|----------|
| 3.0 | 2025-11-30 | Reestruturação completa: código movido para arquivos separados, foco em arquitetura |
| 2.0 | 2025-11-29 | Adicionada 4ª pipeline (module validation), integrações Teams/Dynatrace detalhadas |
| 1.0 | 2025-11-28 | Versão inicial do plano de arquitetura |

---

## ✅ Aprovações

| Papel | Nome | Data | Assinatura |
|-------|------|------|------------|
| Arquiteto Cloud | [Nome] | 2025-11-30 | _______ |
| DevOps Lead | [Nome] | | _______ |
| Security Lead | [Nome] | | _______ |
| CTO | [Nome] | | _______ |

---

**Este documento é confidencial e de uso interno.**  
**Próxima revisão**: Fevereiro 2026
