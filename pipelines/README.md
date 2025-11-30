# Pipelines Terraform - Guia Rápido

Este diretório contém todas as pipelines Jenkins (Shared Library) para gerenciamento da infraestrutura Terraform.

## 📋 Pipelines Disponíveis

### 1. terraform-deploy-pipeline.groovy
**Pipeline principal para deploy e destroy de recursos**

- **Parâmetros:** PROJECT_NAME, ENVIRONMENT, ACTION, GIT_BRANCH
- **Aprovações:** DevOps Team (todos) + Security Team (prod)
- **Integrações:** Teams + Dynatrace
- **Uso:** Deploy/destroy de projetos individuais

### 2. terraform-validation-pipeline.groovy
**Validação automática em Pull/Merge Requests**

- **Trigger:** Automático em MRs
- **Validação:** Paralela em todos os ambientes
- **Integrações:** GitLab (status + comentários)
- **Uso:** Quality gate para MRs

### 3. terraform-drift-detection-pipeline.groovy
**Detecção agendada de drift**

- **Trigger:** Cron (a cada 4 horas)
- **Escopo:** Todos os projetos e ambientes
- **Integrações:** Teams + Dynatrace (apenas quando drift)
- **Uso:** Monitoramento contínuo

### 4. terraform-modules-validation-pipeline.groovy
**Validação de módulos do monorepo**

- **Trigger:** Push e MRs no repo de módulos
- **Validação:** Formato, sintaxe, security, testes
- **Quality Gates:** README obrigatório, testes recomendados
- **Uso:** Quality gate para módulos

## 🔧 Funções Auxiliares

### sendTeamsNotification.groovy
Envia notificações formatadas ao Microsoft Teams.

**Parâmetros:**
- `status`: STARTED | SUCCESS | FAILURE | PENDING_APPROVAL | DRIFT_DETECTED
- `projectName`: Nome do projeto
- `environment`: Ambiente alvo
- `action`: Ação sendo executada
- `buildUrl`: Link para o build Jenkins

### sendDynatraceEvent.groovy
Envia eventos e métricas ao Dynatrace.

**Métricas enviadas:**
- `terraform.pipeline.duration`: Duração da pipeline
- `terraform.pipeline.status`: Status (1=success, 0=failure)
- `terraform.drift.detected`: Drift detectado

## 📦 Instalação no Jenkins

### 1. Criar Jenkins Shared Library

```groovy
// No Jenkins: Manage Jenkins → Configure System → Global Pipeline Libraries

Name: terraform-pipelines
Default version: main
Project repository: https://gitlab.com/org/jenkins-shared-library.git
Credentials: gitlab-credentials
```

### 2. Estrutura do Repositório Shared Library

```
jenkins-shared-library/
├── vars/
│   ├── terraformDeploy.groovy
│   ├── terraformValidation.groovy
│   ├── terraformDriftDetection.groovy
│   ├── terraformModulesValidation.groovy
│   ├── sendTeamsNotification.groovy
│   └── sendDynatraceEvent.groovy
└── README.md
```

### 3. Configurar Credentials no Jenkins

```
Manage Jenkins → Credentials → Add Credentials

- azure-client-id: Azure Service Principal Client ID
- azure-client-secret: Azure Service Principal Secret
- azure-subscription-id: Azure Subscription ID
- azure-tenant-id: Azure Tenant ID
- gitlab-credentials: GitLab personal access token
- teams-webhook-url: Microsoft Teams Incoming Webhook URL
- dynatrace-url: Dynatrace environment URL
- dynatrace-api-token: Dynatrace API token
```

### 4. Criar Jobs no Jenkins

#### Job 1: Terraform Deploy (Parametrizado)

```groovy
@Library('terraform-pipelines') _

terraformDeploy()
```

#### Job 2: Terraform Validation (MultiBranch Pipeline)

```groovy
@Library('terraform-pipelines') _

terraformValidation()
```

#### Job 3: Terraform Drift Detection (Scheduled)

```groovy
@Library('terraform-pipelines') _

terraformDriftDetection()
```

#### Job 4: Terraform Modules Validation (MultiBranch Pipeline)

```groovy
@Library('terraform-pipelines') _

terraformModulesValidation()
```

## 🔐 Segurança

### Permissões de Aprovação

```groovy
// Configure no Jenkins: Manage Jenkins → Configure Global Security

Role-Based Authorization:

devops-team:
  - members: ['user1@company.com', 'user2@company.com']
  - permissions: ['Job.Build', 'Job.Cancel', 'Job.Read']

security-team:
  - members: ['security1@company.com', 'security2@company.com']
  - permissions: ['Job.Build', 'Job.Cancel', 'Job.Read']
```

## 📊 Monitoramento

### Dashboards Dynatrace

Métricas disponíveis para dashboard:
- `terraform.pipeline.duration` por projeto/ambiente
- `terraform.pipeline.status` taxa de sucesso
- `terraform.drift.detected` eventos de drift
- `terraform.resources.count` recursos gerenciados

### Notificações Teams

Eventos notificados:
- Início de deploy
- Aprovações pendentes
- Deploy concluído (sucesso/falha)
- Drift detectado
- Falhas de validação

## 🚀 Exemplo de Uso

### Deploy de um Projeto

1. Acesse o job "Terraform Deploy"
2. Clique em "Build with Parameters"
3. Preencha:
   - PROJECT_NAME: `project-a`
   - ENVIRONMENT: `production`
   - ACTION: `apply`
   - GIT_BRANCH: `main`
4. Clique em "Build"
5. Aguarde aprovação do DevOps Team
6. Aguarde aprovação do Security Team (prod)
7. Deploy será executado

### Validar um Módulo

1. Faça checkout do branch
2. Faça mudanças no módulo
3. Commit e push
4. Crie Merge Request
5. Pipeline de validação executa automaticamente
6. Resultado aparece como status no MR

## 📚 Documentação Adicional

- [Documento de Arquitetura Completo](../terraform-azure-architecture-plan.md)
- [Guia de Desenvolvimento de Módulos](../docs/module-development-guide.md)
- [Runbook de Troubleshooting](../docs/runbook.md)

---

**Última atualização:** 30 de Novembro de 2025  
**Mantido por:** DevOps Team
