# Jenkins Pipelines - Terraform Azure

4 pipelines Jenkins prontas para gerenciar infraestrutura Terraform no Azure.

## 📋 Pipelines Disponíveis

| Pipeline | Arquivo | Trigger | Aprovação | Uso |
|----------|---------|---------|-----------|-----|
| **Deploy** | `terraform-deploy-job.groovy` | Manual | Sim | Deploy/destroy recursos |
| **Validation** | `terraform-validation-job.groovy` | Manual | Não | Validar PRs |
| **Drift Detection** | `terraform-drift-detection-job.groovy` | Auto (4h) | Não | Detectar drift |
| **Modules** | `terraform-modules-validation-job.groovy` | Manual | Não | Validar módulos |

---

## 🚀 Setup Rápido (15 minutos)

### 1. Configurar Credentials no Jenkins

**Manage Jenkins → Credentials → Add Credentials**

Para cada ambiente (prd, qlt, tst):

```
Tipo: Secret text

azure-sp-prd-client-id
azure-sp-prd-client-secret
azure-sp-prd-subscription-id
azure-sp-prd-tenant-id

azure-sp-qlt-client-id
azure-sp-qlt-client-secret
azure-sp-qlt-subscription-id
azure-sp-qlt-tenant-id

azure-sp-tst-client-id
azure-sp-tst-client-secret
azure-sp-tst-subscription-id
azure-sp-tst-tenant-id
```

Mais:

```
Tipo: Username with password
ID: git-credentials
Username: seu-usuario-git
Password: seu-PAT-token
```

### 2. Configurar Docker Agent

**Manage Jenkins → Clouds → Docker**

```
Cloud name: docker-agents
Docker Host URI: unix:///var/run/docker.sock

Agent Template:
  Label: terraform-agent
  Docker Image: jenkins-terraform:latest
  (use a image do diretório /docker)
```

### 3. Criar Jobs no Jenkins

Para cada pipeline:

1. **New Item** → Nome (ex: `terraform-deploy`) → **Pipeline**
2. **Pipeline script:** Copie o conteúdo do arquivo `.groovy` correspondente
3. Marque: ☑ **Use Groovy Sandbox**
4. **Save**

---

## 📖 Detalhes das Pipelines

### 1. Deploy Pipeline

**Arquivo:** `terraform-deploy-job.groovy`

**O que faz:**

- Deploy de recursos Terraform
- Destroy de recursos
- Plan para preview

**Stages:**

1. Initialize
2. Checkout (Git)
3. Validate (format, syntax)
4. Security Scan (Trivy)
5. Cost Estimation (Infracost)
6. Terraform Init (backend Azure)
7. Terraform Plan
8. **Approval** ⏸️ (se apply/destroy)
9. Terraform Apply/Destroy

**Parâmetros:**

- `PROJECT_NAME`: Nome do projeto
- `ENVIRONMENT`: prd, qlt ou tst
- `ACTION`: plan, apply ou destroy
- `GIT_BRANCH`: Branch do Git (default: main)
- `GIT_REPO_URL`: URL do repositório

**Aprovações:**

- TST/QLT: `devops-team` (2 horas)
- PRD: `devops-team` + `security-team` (4 horas)

**Artifacts:**

- tfplan JSON
- Trivy report (XML)
- Infracost report (HTML)

---

### 2. Validation Pipeline

**Arquivo:** `terraform-validation-job.groovy`

**O que faz:**

- Valida código antes de merge
- Security scan
- Cost estimation

**Stages:**

1. Checkout
2. Format Check
3. Terraform Validate
4. Security Scan (Trivy)
5. Cost Estimation (Infracost)

**Parâmetros:**

- `GIT_REPO_URL`: URL do repositório
- `GIT_BRANCH`: Branch a validar

**Quando usar:**

- Antes de merge de PR
- Code review
- Validação rápida

**Artifacts:**

- Trivy report (XML, SARIF)
- Infracost report (JSON, HTML)

---

### 3. Drift Detection Pipeline

**Arquivo:** `terraform-drift-detection-job.groovy`

**O que faz:**

- Detecta mudanças manuais na infraestrutura
- Roda automaticamente a cada 4 horas
- Verifica todos os projetos e ambientes

**Stages:**

1. Para cada projeto/ambiente:
   - Checkout
   - Init com backend
   - Plan com detailed-exitcode
   - Detecta drift (exit code 2)

**Parâmetros:**

- `PROJECTS_LIST`: Projetos separados por vírgula (ex: `power-bi,digital-cabin`)
- `GIT_ORG`: Organização/usuário Git

**Trigger:**

- **Automático:** `H */4 * * *` (a cada 4 horas)
- Também pode executar manualmente

**Output:**

- Status: SUCCESS (sem drift) ou UNSTABLE (drift detectado)
- Artifacts: drift-plan JSON para cada projeto com drift

**⚠️ Importante:** Ajuste `PROJECTS_LIST` com seus projetos reais

---

### 4. Modules Validation Pipeline

**Arquivo:** `terraform-modules-validation-job.groovy`

**O que faz:**

- Valida módulos Terraform compartilhados
- Verifica exemplos e documentação
- Quality checks

**Stages:**

1. Checkout
2. Validate All Modules (format, init, validate)
3. Security Scan (Trivy)
4. Cost Analysis (exemplos)
5. Validate Examples
6. Version Check
7. Quality Report

**Parâmetros:**

- `MODULE_REPO_URL`: URL do repositório de módulos
- `GIT_BRANCH`: Branch a validar

**Quando usar:**

- Antes de versionar módulo
- PR em repositório de módulos
- Quality gate

**Verifica:**

- Format e sintaxe
- Presença de README.md
- Presença de examples/
- variables.tf, outputs.tf
- Validação de exemplos

---

## 🔄 Fluxo de Trabalho

```
Developer cria branch
    ↓
[validation] ← Validar código
    ↓
PR aprovado → Merge
    ↓
[deploy TST] ← Deploy manual
    ↓
Testes
    ↓
[deploy QLT] ← Deploy manual
    ↓
Validação
    ↓
[deploy PRD] ← Deploy manual + Dupla aprovação
    ↓
Produção

[drift-detection] ← Roda automático a cada 4h
```

---

## 🛠️ Ferramentas Necessárias

As pipelines usam estas ferramentas (incluídas no Docker image):

- **Terraform** - IaC engine
- **Trivy** - Security scanning
- **Infracost** - Cost estimation
- **Azure CLI** - Azure authentication

**Docker Image:** Use o Dockerfile em `/docker` para criar a image `jenkins-terraform:latest`

---

## 🔧 Troubleshooting

### Erro: "No such label: terraform-agent"

**Solução:** Configure o Docker agent com label `terraform-agent`

### Erro: "Credentials not found: azure-sp-tst-client-id"

**Solução:** Adicione as credentials no Jenkins (veja seção Setup)

### Erro: "terraform: command not found"

**Solução:** Use o Docker image ou instale Terraform no agent

### Erro: "Permission denied" no Git

**Solução:** Verifique a credential `git-credentials` no Jenkins

### Pipeline de Drift está falhando

**Solução:** Ajuste `GIT_ORG` e `PROJECTS_LIST` com valores corretos

---

## 📊 Exemplos de Uso

### Deploy em TST

```
Job: terraform-deploy
Parâmetros:
  PROJECT_NAME: power-bi
  ENVIRONMENT: tst
  ACTION: apply
  GIT_BRANCH: main
  GIT_REPO_URL: git@github.com:org/power-bi.git
```

### Validar PR

```
Job: terraform-validation
Parâmetros:
  GIT_REPO_URL: git@github.com:org/power-bi.git
  GIT_BRANCH: feature/new-vm
```

### Verificar Drift

```
Job: terraform-drift-detection
Parâmetros:
  PROJECTS_LIST: power-bi,digital-cabin,data-lake
  GIT_ORG: your-org
```

---

## 🔐 Segurança

- ✅ Credentials isoladas por ambiente
- ✅ Approval gates obrigatórios
- ✅ Dupla aprovação para PRD
- ✅ Security scan em todos os deploys
- ✅ Auditoria completa via logs

---

## 📁 Arquivos

```
pipelines/
├── README.md                                    ← Este arquivo
├── terraform-deploy-job.groovy                  ← Deploy/Destroy
├── terraform-validation-job.groovy              ← Validação
├── terraform-drift-detection-job.groovy         ← Drift detection
└── terraform-modules-validation-job.groovy      ← Modules validation
```

---

## 🎯 Checklist de Implementação

- [ ] Credentials configuradas no Jenkins
- [ ] Docker agent configurado
- [ ] Job `terraform-deploy` criado
- [ ] Job `terraform-validation` criado
- [ ] Job `terraform-drift-detection` criado (ajustar PROJECTS_LIST)
- [ ] Job `terraform-modules-validation` criado (opcional)
- [ ] Primeiro teste de deploy executado
- [ ] Drift detection rodando automaticamente

---

**Pronto para começar!** Configure as credentials e crie o primeiro job. 🚀
