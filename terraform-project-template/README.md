# Terraform Project Template

Template para projetos Terraform com backend dinamico no Azure.

## O Que Tem Aqui

```
terraform-project-template/
├── backend.tf          # Backend vazio (dinamico)
├── providers.tf        # Provider Azure
├── variables.tf        # Variaveis padrao
├── main.tf             # Exemplo: Resource Group
├── outputs.tf          # Outputs basicos
├── scripts/
│   ├── init-backend.sh # Inicializa backend
│   └── deploy.sh       # Deploy completo
└── .gitignore          # Arquivos a ignorar
```

## Como Usar para POC

### 1. Copiar Template

```bash
# Copiar para seu projeto
cp -r terraform-project-template ../my-project
cd ../my-project
```

### 2. Configurar Credenciais Azure

```bash
# Exportar credenciais do Service Principal
export ARM_CLIENT_ID="seu-client-id"
export ARM_CLIENT_SECRET="seu-client-secret"
export ARM_TENANT_ID="seu-tenant-id"
export ARM_SUBSCRIPTION_ID="seu-subscription-id"
```

### 3. Deploy

```bash
# Dar permissao aos scripts
chmod +x scripts/*.sh

# Deploy em TST
./scripts/deploy.sh my-project tst

# Deploy em PRD
./scripts/deploy.sh my-project prd
```

## O Que Deve Alterar

### 1. main.tf
Adicione seus recursos Azure aqui. O exemplo tem apenas Resource Group.

### 2. variables.tf
Adicione variaveis especificas do seu projeto.

### 3. outputs.tf
Adicione outputs que voce precisa expor.

### 4. backend.tf
NAO ALTERE. Ele é configurado automaticamente pelos scripts.

## Backend Storage

O estado será salvo em:
- **Storage Account**: stterraformstate
- **Resource Group**: rg-terraform-state
- **Container**: terraform-state-{environment}
- **Key**: {project-name}/terraform.tfstate

Exemplo:
- TST: terraform-state-tst/my-project/terraform.tfstate
- PRD: terraform-state-prd/my-project/terraform.tfstate

## Comandos Uteis

```bash
# Ver outputs
terraform output

# Ver recursos no state
terraform state list

# Formatar codigo
terraform fmt -recursive

# Validar
terraform validate

# Destruir (cuidado!)
terraform destroy -var="environment=tst" -var="project_name=my-project"
```

## Troubleshooting

### Erro: Backend nao inicializado
```bash
./scripts/init-backend.sh my-project tst
```

### Erro: Credenciais invalidas
```bash
# Verificar se esta logado
az account show

# Ou usar credenciais via variaveis
export ARM_CLIENT_ID=...
```

### Erro: Container nao existe
Execute o script de setup primeiro:
```bash
../../scripts/setup/configure-azure-backend.sh
```

## Estrutura de Arquivos

- **backend.tf**: Backend dinamico (vazio)
- **providers.tf**: Provider Azure versao ~> 3.0
- **variables.tf**: environment, project_name, location
- **main.tf**: Seus recursos (comece com Resource Group)
- **outputs.tf**: Valores a expor
- **scripts/init-backend.sh**: Inicializa backend dinamicamente
- **scripts/deploy.sh**: Deploy completo (init + plan + apply)
