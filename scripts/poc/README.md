# POC Scripts

Scripts para testes manuais e demonstração local do fluxo Terraform.

**⚠️ Uso: Apenas para POC/testes locais. Pipelines CI/CD executam Terraform diretamente.**

## Pré-requisitos

1. **Credenciais Azure** (Service Principal)
2. **GitLab Token** (Personal Access Token com `read_repository`)
3. **Backend Azure** configurado (Storage Account + Container)
4. **Docker** (opcional - para ambiente isolado)

## Scripts Disponíveis

| Script | Propósito |
|--------|-----------|
| `azure-login.sh` | Autentica Azure CLI com Service Principal |
| `configure.sh` | Clona repositório e configura backend Terraform |
| `validate-modules.sh` | Valida módulos Terraform |
| `deploy.sh` | Gera plan e aplica mudanças |
| `destroy.sh` | Gera destroy plan e remove recursos |

## Fluxo Completo

### 1. Configurar Variáveis de Ambiente

```bash
# Azure credentials (Service Principal)
export ARM_CLIENT_ID="xxx"
export ARM_CLIENT_SECRET="xxx"
export ARM_SUBSCRIPTION_ID="xxx"
export ARM_TENANT_ID="xxx"

# GitLab token
export GITLAB_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx"
```

### 2. Autenticar Azure

```bash
bash scripts/poc/azure-login.sh
```

Valida credenciais e autentica Azure CLI.

### 3. Configurar Projeto

```bash
bash scripts/poc/configure.sh myapp tst https://gitlab.com/yourgroup/terraform-project-template.git
```

**Parâmetros:**
- `myapp` - Nome do projeto
- `tst` - Ambiente (tst/qlt/prd)
- `<url>` - URL do repositório GitLab

**O que faz:**
- Clona repositório do GitLab
- Configura backend Terraform
- Executa `terraform init`

**Cria:**
- Diretório `myapp/` com código do projeto
- Arquivo `myapp/backend-config.tfbackend`

### 4. (Opcional) Validar Módulos

```bash
bash scripts/poc/validate-modules.sh https://gitlab.com/yourgroup/terraform-modules.git v1.0.0
```

Valida todos os módulos Terraform do repositório.

### 5. Deploy

```bash
bash scripts/poc/deploy.sh myapp tst
```

**O que faz:**
1. Gera plan: `terraform plan -out=tfplan-tst.out`
2. Mostra resumo do plan
3. Solicita confirmação (`yes`)
4. Aplica: `terraform apply tfplan-tst.out`

**⚠️ Sempre requer confirmação manual (`yes`)**

### 6. Destroy

```bash
bash scripts/poc/destroy.sh myapp tst
```

**O que faz:**
1. Lista recursos atuais
2. Gera destroy plan: `terraform plan -destroy -out=tfplan-destroy-tst.out`
3. Mostra resumo
4. Solicita confirmação (`yes`)
5. Aplica: `terraform apply tfplan-destroy-tst.out`

**⚠️ Sempre requer confirmação manual (`yes`)**

## Exemplo Completo

```bash
# 1. Configure credenciais
export ARM_CLIENT_ID="xxx"
export ARM_CLIENT_SECRET="xxx"
export ARM_SUBSCRIPTION_ID="xxx"
export ARM_TENANT_ID="xxx"
export GITLAB_TOKEN="glpat-xxx"

# 2. Autentique Azure
bash scripts/poc/azure-login.sh

# 3. Configure projeto
bash scripts/poc/configure.sh myapp tst https://gitlab.com/yourgroup/terraform-project-template.git

# 4. (Opcional) Valide módulos
bash scripts/poc/validate-modules.sh https://gitlab.com/yourgroup/terraform-modules.git v1.0.0

# 5. Deploy
bash scripts/poc/deploy.sh myapp tst
# Responda: yes

# 6. Verifique
cd myapp
terraform output
terraform state list

# 7. Destroy
cd ..
bash scripts/poc/destroy.sh myapp tst
# Responda: yes
```

## Uso com Docker

```bash
# Start container
docker run -it --rm \
  -e ARM_CLIENT_ID \
  -e ARM_CLIENT_SECRET \
  -e ARM_SUBSCRIPTION_ID \
  -e ARM_TENANT_ID \
  -e GITLAB_TOKEN \
  -v $(pwd):/workspace \
  -w /workspace \
  jenkins-terraform:latest bash

# Dentro do container
bash scripts/poc/azure-login.sh
bash scripts/poc/configure.sh myapp tst https://gitlab.com/...
bash scripts/poc/deploy.sh myapp tst
```

## Detalhes dos Scripts

### azure-login.sh

```bash
bash scripts/poc/azure-login.sh
```

**Requer:**
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`

**Faz:**
- Valida variáveis de ambiente
- Autentica `az login` com Service Principal
- Define subscription padrão

### configure.sh

```bash
bash scripts/poc/configure.sh <project-name> <environment> <gitlab-repo-url>
```

**Exemplo:**
```bash
bash scripts/poc/configure.sh myapp tst https://gitlab.com/yourgroup/terraform-project-template.git
```

**Requer:**
- `GITLAB_TOKEN` environment variable

**Faz:**
1. Clona repositório GitLab em `<project-name>/`
2. Gera `backend-config.tfbackend`
3. Executa `terraform init`

**Cria:**
- `myapp/` - Diretório do projeto
- `myapp/backend-config.tfbackend`
- `myapp/.terraform/`

### validate-modules.sh

```bash
bash scripts/poc/validate-modules.sh <gitlab-repo-url> [tag-or-branch]
```

**Exemplos:**
```bash
bash scripts/poc/validate-modules.sh https://gitlab.com/yourgroup/terraform-modules.git v1.0.0
bash scripts/poc/validate-modules.sh https://gitlab.com/yourgroup/terraform-modules.git main
```

**Faz:**
- Clona repositório de módulos
- Descobre todos os módulos
- Valida cada módulo:
  - `terraform fmt -check`
  - `terraform init`
  - `terraform validate`
- Gera relatório de validação

### deploy.sh

```bash
bash scripts/poc/deploy.sh <project-name> <environment>
```

**Exemplo:**
```bash
bash scripts/poc/deploy.sh myapp tst
```

**Faz:**
1. Muda para diretório `<project-name>/`
2. Executa `terraform plan -var-file=environments/<env>/terraform.tfvars -out=tfplan-<env>.out`
3. Mostra resumo do plan
4. Solicita confirmação: `Do you want to apply these changes? (yes/no):`
5. Executa `terraform apply tfplan-<env>.out`
6. Remove plan file após sucesso

**⚠️ Sem --auto-approve: sempre requer `yes` manual**

### destroy.sh

```bash
bash scripts/poc/destroy.sh <project-name> <environment>
```

**Exemplo:**
```bash
bash scripts/poc/destroy.sh myapp tst
```

**Faz:**
1. Muda para diretório `<project-name>/`
2. Lista recursos: `terraform state list`
3. Executa `terraform plan -destroy -var-file=... -out=tfplan-destroy-<env>.out`
4. Mostra resumo
5. Solicita confirmação: `Type 'yes' to confirm destruction:`
6. Executa `terraform apply tfplan-destroy-<env>.out`
7. Remove plan file após sucesso

**⚠️ Sem --auto-approve: sempre requer `yes` manual**

## Notas Importantes

1. **GitLab Token**: Necessário para clonar repositórios privados e baixar módulos
2. **Confirmação manual**: Deploy e Destroy sempre pedem confirmação
3. **Plan files**: Salvos como `tfplan-<env>.out` e `tfplan-destroy-<env>.out`
4. **CI/CD**: Pipelines Jenkins não usam estes scripts, executam Terraform diretamente
5. **State file**: Permanece no Azure Storage após destroy (para auditoria)
- `backend-config.tfbackend`
- `.terraform/`
- `.terraform.lock.hcl`

## Differences from Jenkins Pipelines

| Aspect | POC Scripts | Jenkins Pipelines |
|--------|-------------|-------------------|
| Execution | Manual | Automated |
| Authentication | Service Principal (manual) | Credentials from Jenkins |
| Approval | Console prompt | Jenkins approval gate |
| Backend config | Generated by script | Generated by pipeline |
| Notifications | None | Teams/Dynatrace |
| Security scan | Manual (if needed) | Automated (Trivy) |
| Cost analysis | Manual (if needed) | Automated (Infracost) |
| Artifacts | Local files | Archived in Jenkins |

## Troubleshooting

### Error: Not authenticated

**Symptom:** `Not authenticated to Azure`

**Solution:**
```bash
./azure-login.sh
```

### Error: Backend not found

**Symptom:** `Resource group 'rg-terraform-backend' not found`

**Solution:**
```bash
cd ../setup
./configure-azure-backend.sh
```

### Error: Workspace path not found

**Symptom:** `Workspace path not found: ../../terraform-project-template`

**Solution:**
```bash
# Use absolute path or correct relative path
./configure.sh mypoc tst /full/path/to/terraform-project-template
```

### Error: State locked

**Symptom:** `Error acquiring the state lock`

**Solution:**
```bash
# Wait for lock to release, or force unlock
cd ../../terraform-project-template
terraform force-unlock <lock-id>
```

## Security Notes

### For POC/Testing
- Use dedicated service principal for testing
- Limit scope to test subscription
- Use short-lived credentials
- Never commit credentials to git

### Credentials Storage
- ❌ Never hardcode credentials in scripts
- ❌ Never commit credentials to repository
- ✅ Use environment variables
- ✅ Use Azure Key Vault (future)

## Next Steps

After POC validation:
1. Migrate workflow to Jenkins pipelines (already created)
2. Configure Jenkins credentials
3. Set up approval gates
4. Enable notifications (Teams/Dynatrace)
5. Archive POC scripts for reference

## Notes

- Scripts are for **demonstration purposes only**
- Production deployments use Jenkins pipelines
- Scripts assume backend already configured
- All scripts use bash (macOS/Linux/WSL compatible)
- Windows users: Use Git Bash or WSL

## Related Documentation

- [Pipeline Documentation](../../pipelines/README.md)
- [Backend Setup](../setup/configure-azure-backend.sh)
- [Docker Image](../../docker/README.md)
- [Project Template](../../terraform-project-template/README.md)
