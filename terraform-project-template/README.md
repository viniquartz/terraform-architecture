# Terraform Project Template

Template padrão para projetos Terraform Azure usando módulos versionados.

## Conteúdo

- [O que está incluído](#o-que-está-incluído)
- [Arquitetura](#arquitetura)
- [Pré-requisitos](#pré-requisitos)
- [Uso com Scripts POC](#uso-com-scripts-poc)
- [Uso com Pipelines Jenkins](#uso-com-pipelines-jenkins)
- [Customização](#customização)
- [Troubleshooting](#troubleshooting)

## O que está incluído

```text
terraform-project-template/
├── backend.tf                   # Backend Azure (configurado automaticamente)
├── providers.tf                 # Azure provider (azurerm ~> 3.0)
├── variables.tf                 # Variáveis com validação
├── main.tf                      # Infraestrutura usando módulos v1.0.0
├── outputs.tf                   # Outputs padrão
├── environments/                # Configurações por ambiente
│   ├── tst/
│   │   └── terraform.tfvars    # Test environment (exemplo incluído)
│   ├── qlt/                    # Quality environment (criar conforme necessário)
│   └── prd/                    # Production environment (criar conforme necessário)
├── README.md                    # Esta documentação
└── .gitignore                   # Proteção de arquivos sensíveis
```

## Arquitetura

Este template demonstra:

- **Naming Convention**: `azr_<env>_<project><version>_<region>_<resource>`
- **Networking**: VNet com múltiplas subnets (app, data)
- **Segurança**: NSG com regras de segurança
- **Storage**: Storage Account com containers
- **Opcional**: VM Linux e ACR (comentados por padrão)

Todos os recursos usam módulos compartilhados do repositório `terraform-azure-modules` versão **v1.0.0**.

Exemplo de naming gerado:

- Resource Group: `azr_tst_myapp01_brs_rg`
- Virtual Network: `azr_tst_myapp01_brs_vnet`
- Storage Account: `azrtstmyapp01brsst`

## Pré-requisitos

- Terraform >= 1.5.0 instalado
- Azure CLI instalado e autenticado
- Credenciais de Service Principal (criadas via scripts de setup)
- Backend Azure Storage configurado
- Acesso Git SSH configurado (para fontes dos módulos)

## Uso com Scripts POC

Para testes locais manuais, use os scripts em `scripts/poc/` do repositório principal:

```bash
# 1. Clonar este template
git clone <repo-url> my-project
cd my-project

# 2. Editar configuração do ambiente desejado
nano environments/tst/terraform.tfvars

# 3. Definir credenciais Azure
export ARM_CLIENT_ID="xxx"
export ARM_CLIENT_SECRET="xxx"
export ARM_SUBSCRIPTION_ID="xxx"
export ARM_TENANT_ID="xxx"

# 4. Navegar para scripts POC (repositório terraform-azure-project)
cd ../terraform-azure-project/scripts/poc

# 5. Autenticar
./azure-login.sh

# 6. Configurar backend + init
./configure.sh myproject tst ../../my-project

# 7. Deploy (especificando arquivo tfvars)
cd ../../my-project
terraform plan -var-file="environments/tst/terraform.tfvars"
terraform apply -var-file="environments/tst/terraform.tfvars"

# 8. Destroy
terraform destroy -var-file="environments/tst/terraform.tfvars"
```

**Nota:** Os scripts POC geram automaticamente o arquivo `backend-config.tfbackend` no seu workspace.

## Uso com Pipelines Jenkins

Para uso em produção via Jenkins:

```groovy
pipeline {
    agent {
        docker {
            image 'jenkins-terraform:latest'
        }
    }
    
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['tst', 'qlt', 'prd'])
        string(name: 'PROJECT_NAME', defaultValue: 'myproject')
        choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'])
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'git@github.com:org/my-project.git'
            }
        }
        
        stage('Deploy') {
            steps {
                // Pipeline injeta backend automaticamente
                sh '''
                    terraform init \
                      -backend-config="resource_group_name=rg-terraform-state" \
                      -backend-config="storage_account_name=stterraformstate" \
                      -backend-config="container_name=terraform-state-${ENVIRONMENT}" \
                      -backend-config="key=${PROJECT_NAME}.tfstate"
                    
                    terraform ${ACTION} -var-file="environments/${ENVIRONMENT}/terraform.tfvars"
                '''
            }
        }
    }
}
```

**Nota:** O pipeline Jenkins do repositório `terraform-azure-project` já faz isso automaticamente.

## Customização

### Configurações por Ambiente

Cada ambiente possui sua própria pasta. Apenas TST está incluído como exemplo:

**environments/tst/terraform.tfvars** - Ambiente de teste (incluído)
```hcl
environment  = "tst"
project_name = "myapp"
location     = "brazilsouth"
```

**Criar para outros ambientes:**

```bash
# Quality
cat > environments/qlt/terraform.tfvars <<EOF
environment  = "qlt"
project_name = "myapp"
location     = "brazilsouth"
EOF

# Production
cat > environments/prd/terraform.tfvars <<EOF
environment  = "prd"
project_name = "myapp"
location     = "brazilsouth"
EOF
```

**Nota:** Arquivos `terraform.tfvars` em `environments/*/` são commitados ao git. Para valores sensíveis (SSH keys, secrets), use variáveis de ambiente ou Azure Key Vault.

### main.tf

Adicione seus recursos Azure. O exemplo atual inclui:

- Resource Group (obrigatório)
- VNet com subnets
- NSG com regras de segurança
- Storage Account
- Opcional: VM, ACR (comentados)

**Importante:** Todos os módulos referenciam `terraform-azure-modules` versão **v1.0.0**.

### variables.tf

Adicione variáveis específicas do projeto. Variáveis atuais:

- `environment` (validado: prd, qlt, tst)
- `project_name` (validado: lowercase, números, hífens)
- `location` (default: brazilsouth)
- `admin_ssh_key` (opcional, para VMs)

### outputs.tf

Adicione outputs para expor informações dos recursos.

### backend.tf

**NÃO ALTERE**. Configuração do backend é injetada automaticamente:
- Scripts POC: geram `backend-config.tfbackend`
- Pipelines Jenkins: injetam via parâmetros `-backend-config`

## Backend Storage

State files armazenados no Azure Storage:

- **Storage Account**: `stterraformstate`
- **Resource Group**: `rg-terraform-state`
- **Container Pattern**: `terraform-state-{environment}`
- **Key Pattern**: `{project-name}.tfstate`

**Exemplos:**

- TST: `terraform-state-tst/myapp.tfstate`
- QLT: `terraform-state-qlt/myapp.tfstate`
- PRD: `terraform-state-prd/myapp.tfstate`

**Configuração automática:**
- Scripts POC: criam arquivo `backend-config.tfbackend` automaticamente
- Pipelines: injetam configuração durante execução do job

## Comandos Úteis

```bash
# Ver outputs
terraform output

# Listar recursos no state
terraform state list

# Formatar código
terraform fmt -recursive

# Validar configuração
terraform validate

# Plan com variáveis específicas
terraform plan -var="environment=tst" -var="project_name=myapp"

# Mostrar state atual
terraform show

# Refresh state
terraform refresh

# Destroy
terraform destroy
```

## Troubleshooting

### Erro: Backend não inicializado

**Sintoma:** `Error: Backend initialization required`

**Solução:**

```bash
# Com scripts POC
cd ../terraform-azure-project/scripts/poc
./configure.sh myproject tst /path/to/workspace

# Ou manualmente
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=stterraformstate" \
  -backend-config="container_name=terraform-state-tst" \
  -backend-config="key=myproject.tfstate"
```

### Erro: Credenciais inválidas

**Sintoma:** `Error: building account: could not acquire access token`

**Solução:**

```bash
# Verificar login
az account show

# Ou usar Service Principal
export ARM_CLIENT_ID="xxx"
export ARM_CLIENT_SECRET="xxx"
export ARM_TENANT_ID="xxx"
export ARM_SUBSCRIPTION_ID="xxx"

# Testar autenticação
az login --service-principal \
  -u $ARM_CLIENT_ID \
  -p $ARM_CLIENT_SECRET \
  --tenant $ARM_TENANT_ID
```

### Erro: Container não existe

**Sintoma:** `Error: Failed to get existing workspaces: containers.Client#ListBlobs`

**Solução:** Backend não foi configurado. Execute scripts de setup do repositório principal:

```bash
cd ../terraform-azure-project/scripts/setup
./configure-azure-backend.sh
./create-service-principals.sh
```

### Erro: Module source não encontrado

**Sintoma:** `Error: Failed to download module`

**Solução:** Configurar acesso SSH ao Git:

```bash
# Testar acesso SSH
ssh -T git@github.com

# Adicionar chave SSH se necessário
ssh-add ~/.ssh/id_rsa
```

### Erro: Resource já existe

**Sintoma:** `A resource with the ID already exists`

**Solução:**

```bash
# Opção 1: Importar recurso existente
terraform import azurerm_resource_group.main /subscriptions/<sub-id>/resourceGroups/<rg-name>

# Opção 2: Mudar nome do projeto ou destruir recursos anteriores
terraform destroy
```

## Referências

### Fontes dos Módulos

Todos os módulos usam referências versionadas do repositório terraform-azure-modules:

```hcl
module "naming" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/foundation/naming?ref=v1.0.0"
}

module "vnet" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/vnet?ref=v1.0.0"
}
```

### Versões dos Módulos

- **v1.0.0**: Release inicial estável (recomendado)
- Verifique [releases do terraform-azure-modules](https://github.com/org/terraform-azure-modules/releases) para atualizações

### Repositórios Relacionados

- **terraform-azure-modules**: Módulos Terraform reutilizáveis (repositório separado)
- **terraform-azure-project**: Pipelines CI/CD, imagens Docker, scripts (repositório separado)

### Documentação

- Este README
- Documentação dos módulos: repositório terraform-azure-modules
- Documentação CI/CD: repositório terraform-azure-project
- Scripts POC: `terraform-azure-project/scripts/poc/README.md`

### Suporte

Para dúvidas:

1. Verifique seção Troubleshooting deste README
2. Revise documentação dos módulos no repositório terraform-azure-modules
3. Consulte documentação CI/CD no repositório terraform-azure-project
4. Verifique scripts POC em `terraform-azure-project/scripts/poc/`
