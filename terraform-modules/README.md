# Terraform Azure Modules

Collection of reusable Terraform modules for Azure infrastructure.

## Available Modules

### Networking
- **[vnet](vnet/)** - Azure Virtual Network
- **[subnet](subnet/)** - Azure Subnet with service endpoints support
- **[nsg](nsg/)** - Network Security Group
- **[nsg-rules](nsg-rules/)** - Custom NSG security rules (multi-rule support)
- **[ssh](ssh/)** - SSH security rule (single rule)

### Compute
- **[vm-linux](vm-linux/)** - Linux Virtual Machine with SSH authentication

## Module Standards

All modules follow these standards:

- ✅ Terraform >= 1.5.0 required
- ✅ Azure Provider ~> 3.0 required
- ✅ Input validation where applicable
- ✅ Comprehensive descriptions on all variables
- ✅ Security best practices enforced
- ✅ Example usage included
- ✅ README documentation

## Quick Start

```hcl
# Example: Create a complete network infrastructure
module "vnet" {
  source = "./terraform-modules/vnet"

  vnet_name           = "my-vnet"
  location            = "West Europe"
  resource_group_name = "my-rg"
  address_space       = ["10.0.0.0/16"]

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

module "subnet" {
  source = "./terraform-modules/subnet"

  subnet_name          = "my-subnet"
  resource_group_name  = "my-rg"
  virtual_network_name = module.vnet.vnet_name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

module "nsg" {
  source = "./terraform-modules/nsg"

  nsg_name            = "my-nsg"
  location            = "West Europe"
  resource_group_name = "my-rg"
  subnet_id           = module.subnet.subnet_id

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Module Details

### VNET
Creates an Azure Virtual Network with configurable address space.

**Key Features:**
- CIDR validation
- Required Environment tag
- Multiple address spaces support

### Subnet
Creates a subnet within a VNET with optional service endpoints.

**Key Features:**
- CIDR validation
- Service endpoints (Storage, SQL, KeyVault, etc.)
- NSG association via nsg module

### NSG
Creates a Network Security Group with optional subnet association.

**Key Features:**
- Automatic subnet association
- Tagging support
- Use with nsg-rules or ssh modules

### NSG Rules
Add multiple custom security rules to an existing NSG.

**Key Features:**
- Multiple rules in one module call
- Full validation (direction, access, protocol, priority)
- For-each loop for efficiency

**When to use:**
- Multiple custom rules needed
- HTTP/HTTPS/custom ports
- Complex security requirements

### SSH
Add a single SSH rule to an existing NSG.

**Key Features:**
- Simple SSH access (port 22)
- Configurable source IP/CIDR
- Priority control

**When to use:**
- Only SSH access needed
- Simple use case
- Quick setup

### VM Linux
Creates a Linux VM with network interface and optional public IP.

**Key Features:**
- SSH-only authentication (password disabled)
- Ubuntu 22.04 LTS default
- Most affordable size default (Standard_B1s)
- Flexible public IP configuration
- SSH command output

## Validation Rules

Modules include input validation for:

- **CIDR blocks** - All network addresses validated
- **Resource names** - Character limits enforced
- **VM sizes** - Must start with 'Standard_'
- **Tags** - Environment key required when tags provided
- **NSG rules** - Direction, access, protocol, priority ranges
- **Service endpoints** - Must start with 'Microsoft.'

## Security Best Practices

- VM password authentication disabled by default
- SSH key authentication required
- NSG rules validated for proper configuration
- Tags enforced for resource tracking
- Provider versions locked

## Contributing

When creating new modules:

1. Follow the standard structure (main.tf, variables.tf, outputs.tf, versions.tf)
2. Add comprehensive variable descriptions
3. Include validation where applicable
4. Create README.md with examples
5. Add at least one basic example in examples/basic/
6. Test in dev environment first

## Documentation

Each module has its own README with:
- Usage examples
- Requirements table
- Inputs table
- Outputs table
- Validation rules
- Notes and best practices

## Version Requirements

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
