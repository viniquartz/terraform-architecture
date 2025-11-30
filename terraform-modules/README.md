# Terraform Azure Modules

Repositório de módulos reutilizáveis do Terraform para Azure (Monorepo).

## 📁 Estrutura Sugerida

```
terraform-azure-modules/
├── README.md
├── .gitignore
├── .gitlab-ci.yml                    # Pipeline de validação
├── networking/
│   ├── virtual-network/
│   │   ├── README.md
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   ├── examples/
│   │   │   └── complete/
│   │   │       ├── main.tf
│   │   │       └── README.md
│   │   └── tests/
│   │       └── virtual_network_test.go
│   ├── subnet/
│   ├── nsg/
│   ├── route-table/
│   ├── application-gateway/
│   └── vpn-gateway/
├── compute/
│   ├── virtual-machine/
│   ├── vmss/
│   ├── aks/
│   └── container-instances/
├── storage/
│   ├── storage-account/
│   ├── file-share/
│   └── managed-disk/
├── database/
│   ├── sql-database/
│   ├── postgresql/
│   ├── mysql/
│   └── cosmos-db/
├── security/
│   ├── key-vault/
│   ├── key-vault-secret/
│   └── private-endpoint/
└── monitoring/
    ├── log-analytics/
    ├── application-insights/
    └── diagnostic-settings/
```

## 📋 Padrão de Módulo

Cada módulo deve seguir esta estrutura:

### 1. main.tf
```hcl
# Implementação do recurso principal
resource "azurerm_resource" "main" {
  # ...
}
```

### 2. variables.tf
```hcl
variable "name" {
  description = "Nome do recurso"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "Nome deve conter apenas letras minúsculas, números e hífens."
  }
}

variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags do recurso"
  type        = map(string)
  default     = {}
}
```

### 3. outputs.tf
```hcl
output "id" {
  description = "ID do recurso criado"
  value       = azurerm_resource.main.id
}

output "name" {
  description = "Nome do recurso criado"
  value       = azurerm_resource.main.name
}
```

### 4. versions.tf
```hcl
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}
```

### 5. README.md
Deve conter:
- Descrição do módulo
- Requisitos
- Exemplos de uso
- Inputs (variáveis)
- Outputs
- Recursos criados

### 6. examples/
Exemplos práticos de uso do módulo

### 7. tests/
Testes automatizados usando Terratest

## 🔖 Versionamento

Use **Git Tags** para versionar os módulos:

```bash
git tag -a v1.0.0 -m "Initial release of virtual-network module"
git push origin v1.0.0
```

Siga **Semantic Versioning**:
- `v1.0.0` - Major release (breaking changes)
- `v1.1.0` - Minor release (new features)
- `v1.1.1` - Patch release (bug fixes)

## 📦 Usando Módulos

### Referência por Tag
```hcl
module "network" {
  source = "git::https://gitlab.com/org/terraform-azure-modules.git//networking/virtual-network?ref=v1.0.0"
  
  name                = "vnet-example"
  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]
}
```

### Referência por Branch
```hcl
module "network" {
  source = "git::https://gitlab.com/org/terraform-azure-modules.git//networking/virtual-network?ref=main"
  # ...
}
```

## ✅ Checklist para Novos Módulos

- [ ] Código implementado (main.tf)
- [ ] Variáveis documentadas (variables.tf)
- [ ] Outputs definidos (outputs.tf)
- [ ] Versões especificadas (versions.tf)
- [ ] README completo
- [ ] Exemplo de uso funcional
- [ ] Testes Terratest implementados
- [ ] Validações adicionadas nas variáveis
- [ ] Security scan passou (TFSec + Checkov)
- [ ] Code review aprovado
- [ ] Tag de versão criada

## 🧪 Executando Testes

```bash
cd networking/virtual-network/tests
go test -v -timeout 30m
```

## 🔒 Segurança

Todos os módulos são escaneados automaticamente:
- **TFSec**: Análise de segurança estática
- **Checkov**: Policy-as-code compliance

## 📝 Contribuindo

1. Crie uma branch: `git checkout -b feature/new-module`
2. Desenvolva o módulo seguindo o padrão
3. Execute testes localmente
4. Crie um Merge Request
5. Aguarde aprovação da pipeline de validação
6. Após merge, crie uma tag de versão

## 🔗 Links Úteis

- [Terraform Registry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Naming Convention](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- [Terratest Documentation](https://terratest.gruntwork.io/)

## 📞 Suporte

- Canal Teams: #terraform-modules
- Email: devops-team@company.com
- Issues: GitLab Issues
