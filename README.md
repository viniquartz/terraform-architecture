# Terraform Azure Architecture Project

Projeto de modernização de infraestrutura Azure usando Terraform com as melhores práticas do mercado.

## 📁 Estrutura do Repositório

```
terraform-azure-project/
├── README.md                          # Este arquivo
├── docs/                              # Documentação
│   ├── architecture-plan.md           # Plano de arquitetura completo (v3.0)
│   ├── runbook.md                     # Runbook operacional
│   └── troubleshooting.md             # Guia de troubleshooting
├── pipelines/                         # Jenkins Shared Library
│   ├── README.md                      # Documentação das pipelines
│   ├── terraform-deploy-pipeline.groovy
│   ├── terraform-validation-pipeline.groovy
│   ├── terraform-drift-detection-pipeline.groovy
│   ├── terraform-modules-validation-pipeline.groovy
│   ├── sendTeamsNotification.groovy
│   └── sendDynatraceEvent.groovy
├── scripts/                           # Scripts auxiliares
│   ├── setup/                         # Scripts de setup inicial
│   │   ├── configure-azure-backend.sh
│   │   └── create-service-principals.sh
│   └── import/                        # Scripts para import de recursos
│       └── generate-import-commands.sh
├── terraform-modules/                 # Monorepo de módulos (exemplo)
│   └── README.md                      # Estrutura sugerida
└── examples/                          # Exemplos de uso
    └── new-project/                   # Template para novos projetos
        ├── main.tf
        ├── variables.tf
        └── terraform.tfvars.example
```

## 🚀 Quick Start

### 1. Pré-requisitos

- Azure CLI instalado e configurado
- Terraform >= 1.5.0
- GitLab account com acesso aos repositórios
- Jenkins com plugin Shared Library configurado

### 2. Configuração Inicial

```bash
# Clone o repositório
git clone https://gitlab.com/org/terraform-azure-project.git
cd terraform-azure-project

# Configure Azure CLI
az login
az account set --subscription <subscription-id>

# Configure Jenkins credentials (ver docs/deployment-guide.md)
```

### 3. Usar as Pipelines

Ver documentação completa em [`pipelines/README.md`](pipelines/README.md)

## 📚 Documentação

- **[Plano de Arquitetura](docs/architecture-plan.md)** - Documento completo com decisões arquiteturais, estrutura de repositórios, pipelines, e timeline detalhado (v3.0)
- **[Runbook Operacional](docs/runbook.md)** - Procedimentos operacionais, emergências, e tarefas rotineiras
- **[Troubleshooting](docs/troubleshooting.md)** - Resolução de problemas comuns e debugging avançado

## 🏗️ Arquitetura

### Pipelines Centralizadas

- **terraform-deploy-pipeline**: Deploy/destroy de projetos
- **terraform-validation-pipeline**: Validação automática em MRs
- **terraform-drift-detection-pipeline**: Detecção de drift (4 em 4 horas)
- **terraform-modules-validation-pipeline**: Validação de módulos

### Integrações

- **Microsoft Teams**: Notificações em tempo real
- **Dynatrace**: Métricas e observabilidade
- **GitLab**: CI/CD e versionamento
- **Jenkins**: Orquestração das pipelines

## 🔐 Segurança

### Aprovações Multi-Nível

| Ambiente | Aprovação 1 | Aprovação 2 | Timeout |
|----------|-------------|-------------|---------|
| Development | DevOps Team | - | 2h |
| Testing | DevOps Team | - | 2h |
| Staging | DevOps Team | - | 4h |
| **Production** | **DevOps Team** | **Security Team** | **4h** |

### Scanning de Segurança

- **TFSec**: Análise estática de código Terraform
- **Checkov**: Policy-as-code scanning
- Executado automaticamente em todas as pipelines

## 📦 Módulos Terraform

Os módulos Terraform devem ser mantidos em repositório separado (monorepo):
- `terraform-azure-modules` (ver exemplo em `terraform-modules/README.md`)

### Módulos Disponíveis

- `networking/virtual-network`
- `networking/subnet`
- `networking/nsg`
- `compute/virtual-machine`
- `compute/vmss`
- `compute/aks`
- `storage/storage-account`
- `database/sql-database`
- `security/key-vault`
- E mais...

## 🎯 Abordagem de Implementação

### Fase 1: Novos Projetos (Semanas 1-8)
- Focar em implementar Terraform para novos projetos
- Validar módulos, pipelines e processos
- Construir expertise no time

### Fase 2: Migração Legado (Semanas 9-20)
- Import de recursos existentes
- Priorizar por criticidade
- Usar ferramentas de import automatizado

## 🛠️ Scripts Disponíveis

```bash
# Setup
./scripts/setup/configure-azure-backend.sh
./scripts/setup/create-service-principals.sh

# Import de recursos legados
./scripts/import/generate-import-commands.sh <resource-group>
```

## 📊 Monitoramento

### Métricas Dynatrace

- `terraform.pipeline.duration`: Duração das pipelines
- `terraform.pipeline.status`: Taxa de sucesso
- `terraform.drift.detected`: Eventos de drift
- `terraform.resources.count`: Recursos gerenciados

### Dashboards Sugeridos

- Pipeline success rate por projeto
- Duração média de deploy por ambiente
- Drift detection timeline
- Recursos gerenciados por projeto

## 🤝 Contribuindo

1. Crie uma branch a partir de `develop`
2. Faça suas alterações
3. Execute validações locais
4. Crie um Merge Request
5. Aguarde aprovação do code review
6. Pipeline de validação deve passar

## 📝 Convenções

### Naming Convention

- Resource Groups: `rg-{workload}-{env}-{region}`
- Storage Accounts: `st{workload}{env}{region}`
- Virtual Networks: `vnet-{workload}-{env}-{region}`

Ver detalhes completos em [`docs/architecture-plan.md`](docs/architecture-plan.md)

### Tags Obrigatórias

```hcl
tags = {
  Environment  = "production"
  ManagedBy    = "Terraform"
  Project      = "project-name"
  CostCenter   = "IT-Infrastructure"
  Owner        = "team@company.com"
}
```

## 🚨 Suporte

- **Issues**: Criar issue no GitLab
- **Teams**: Canal #terraform-azure
- **Email**: devops-team@company.com
- **Runbook**: [`docs/runbook.md`](docs/runbook.md)

## 📅 Timeline

- **Fase 1 (Semanas 1-8)**: Novos projetos
- **Fase 2 (Semanas 9-20)**: Migração legado
- **Go-Live**: Junho 2026

## 👥 Time

- **Arquiteto Cloud Azure**: Responsável pela arquitetura
- **DevOps Team**: Implementação e operação
- **Security Team**: Aprovações e compliance
- **Platform Team**: Suporte aos módulos

## 📄 Licença

Proprietary - Uso interno apenas

---

**Última atualização:** 30 de Novembro de 2025  
**Versão do Documento:** 3.0  
**Mantido por:** DevOps Team

## 🔄 Histórico de Versões

| Versão | Data | Mudanças |
|--------|------|----------|
| 3.0 | 2025-11-30 | Estrutura final com pipelines centralizadas, integração Teams/Dynatrace, e abordagem faseada |
| 2.0 | 2025-11-27 | Versão inicial da arquitetura |
