# Terraform Azure - Documentation and Templates

Infrastructure as Code templates, documentation, and CI/CD pipelines for Azure using Terraform.

> **Note**: This repository contains documentation and reference materials. For production-ready versioned modules, see [terraform-azure-modules](https://gitlab.com/yourgroup/terraform-azure-modules).

## 📚 Documentation

- **[Setup Guide](docs/SETUP-TRACKING.md)** - 🚧 Complete setup guide (work in progress)
- **[Architecture Plan](docs/architecture-plan.md)** - Solution architecture overview
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions
- **[Runbook](docs/runbook.md)** - Operational procedures

## 🚀 Quick Start

### Option 1: Using Versioned Modules (Recommended for Production)

```hcl
module "vnet" {
  source = "git@gitlab.com:yourgroup/terraform-azure-modules.git//modules/vnet?ref=v1.0.0"
  
  vnet_name           = "my-vnet"
  location            = "West Europe"
  resource_group_name = "my-rg"
  address_space       = ["10.0.0.0/16"]
  
  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### Option 2: Using Template (For Testing/Development)

```bash
# 1. Clone repository
git clone git@gitlab.com:yourgroup/terraform-azure-project.git
cd terraform-azure-project/template/

# 2. Copy environment configuration
cp environments/non-prd/terraform.tfvars terraform.tfvars

# 3. Edit variables
vim terraform.tfvars

# 4. Initialize and deploy
terraform init
terraform plan
terraform apply
```

## 📁 Repository Structure

```
terraform-azure-project/
├── docs/                          # 📖 Documentation
│   ├── POC-SETUP-GUIDE.md        # Complete setup guide
│   ├── REPOSITORY-STRATEGY.md     # Git strategy
│   ├── BACKEND-CONFIG.md          # Backend configuration
│   └── architecture-plan.md       # Architecture docs
│
├── docker/                        # 🐳 Docker for Jenkins Agent
│   ├── Dockerfile                 # Jenkins agent image
│   ├── docker-compose.yml         # Local testing
│   ├── env.example                # Environment variables template
│   └── README.md                  # Docker usage guide
│
├── pipelines/                     # 🔄 Jenkins Pipelines
│   ├── terraform-deploy-pipeline.groovy
│   ├── terraform-validation-pipeline.groovy
│   ├── terraform-drift-detection-pipeline.groovy
│   ├── sendTeamsNotification.groovy
│   └── sendDynatraceEvent.groovy
│
├── scripts/                       # 🔧 Setup Scripts
│   ├── setup/
│   │   ├── configure-azure-backend.sh
│   │   └── create-service-principals.sh
│   └── import/
│       └── generate-import-commands.sh
│
├── template/                      # 📋 Infrastructure Template
│   ├── main.tf                    # Main configuration
│   ├── variables.tf               # Variables declaration
│   ├── outputs.tf                 # Outputs
│   ├── providers.tf               # Provider configuration
│   └── environments/
│       ├── prd/terraform.tfvars
│       └── non-prd/terraform.tfvars
│
└── terraform-modules/             # 📦 Modules (Reference Only)
    ├── vnet/                      # Virtual Network
    ├── subnet/                    # Subnet
    ├── nsg/                       # Network Security Group
    ├── ssh/                       # SSH Security Rule
    ├── vm-linux/                  # Linux Virtual Machine
    └── nsg-rules/                 # Custom NSG Rules
```

## 🔧 Available Modules

| Module | Description | Documentation |
|--------|-------------|---------------|
| **vnet** | Azure Virtual Network with CIDR validation | [README](terraform-modules/vnet/README.md) |
| **subnet** | Subnet with service endpoints support | [README](terraform-modules/subnet/README.md) |
| **nsg** | Network Security Group with optional subnet association | [README](terraform-modules/nsg/README.md) |
| **ssh** | Quick SSH security rule (port 22) | [README](terraform-modules/ssh/README.md) |
| **vm-linux** | Linux VM with SSH-only authentication | [README](terraform-modules/vm-linux/README.md) |
| **nsg-rules** | Multiple custom security rules | [README](terraform-modules/nsg-rules/README.md) |

## 🐳 Docker Agent

Jenkins agent with all required tools pre-installed:

- Git
- Azure CLI
- Terraform 1.5.7
- TFSec (security scanner)
- Checkov (IaC scanner)
- terraform-docs
- Python 3 + packages
- Java 17 (for Jenkins)

See [docker/README.md](docker/README.md) for build and usage instructions.

## 🔄 CI/CD Pipelines

### Available Pipelines

1. **terraform-validation-pipeline.groovy**
   - Format check (`terraform fmt`)
   - Validation (`terraform validate`)
   - Security scan (TFSec + Checkov)
   - Documentation generation

2. **terraform-deploy-pipeline.groovy**
   - Terraform init with remote backend
   - Plan/Apply/Destroy
   - Teams notifications
   - Dynatrace events

3. **terraform-drift-detection-pipeline.groovy**
   - Scheduled drift detection
   - Automated alerts
   - Drift reports

See [pipelines/README.md](pipelines/README.md) for detailed pipeline documentation.

## 🏗️ Setup Guide

### For DevOps/Platform Team

Follow the complete [POC Setup Guide](docs/POC-SETUP-GUIDE.md) to:

1. Configure Azure (Service Principals, Backend, etc.)
2. Setup GitLab repositories
3. Configure Jenkins with Docker agent
4. Deploy first infrastructure

### For Developers

1. Clone terraform-azure-modules repository
2. Reference modules with specific versions
3. Deploy using Jenkins pipelines

## 🔐 Security Features

- ✅ SSH-only authentication for VMs (password disabled)
- ✅ Azure backend with state locking
- ✅ Encryption at rest and in transit
- ✅ TFSec security scanning
- ✅ Checkov compliance checking
- ✅ Input validations (CIDR, tags, etc.)
- ✅ RBAC on Storage Account

## 📊 State Management

- **Backend**: Azure Storage Account with blob storage
- **Locking**: Native blob leases (15s timeout)
- **Versioning**: Enabled with 14-day soft delete
- **Encryption**: Microsoft-managed keys
- **Isolation**: Separate containers per environment

See [BACKEND-CONFIG.md](docs/BACKEND-CONFIG.md) for detailed configuration.

## 🌍 Multi-Environment Support

```
Environments:
├── PRD (Production)
│   ├── Service Principal: terraform-azure-prd
│   ├── Backend Container: tfstate-prd
│   └── Approvals: Required
│
└── NON-PRD (Dev/QA)
    ├── Service Principal: terraform-azure-non-prd
    ├── Backend Container: tfstate-non-prd
    └── Approvals: Optional
```

## 🛠️ Prerequisites

- **Azure**: Active subscription with Contributor permissions
- **Terraform**: Version >= 1.5.0
- **Git**: For repository access
- **Jenkins**: Version 2.400+ with Docker plugin
- **Docker**: For Jenkins agent

## 📝 Contributing

This repository follows documentation-driven development:

1. Update documentation first
2. Create feature branch
3. Commit with conventional commits
4. Create Merge Request
5. Get approval from maintainers

See [REPOSITORY-STRATEGY.md](docs/REPOSITORY-STRATEGY.md) for detailed workflow.

## 🔗 Related Repositories

- **[terraform-azure-modules](https://gitlab.com/yourgroup/terraform-azure-modules)** - Production-ready versioned modules

## 📞 Support

- **DevOps Team**: devops@company.com
- **Documentation**: See [docs/](docs/) folder
- **Issues**: Create issue in GitLab

## 📜 License

Internal use only - Company Name

---

**Note**: For production deployments, always use versioned modules from [terraform-azure-modules](https://gitlab.com/yourgroup/terraform-azure-modules) repository.

# Editar variaveis do ambiente
vim environments/non-prd/terraform.tfvars  # ou prd

# Colar sua chave SSH publica no campo ssh_public_key
```

### 4. Deploy

```bash
# Inicializar
terraform init

# Non-PRD
terraform plan -var-file="environments/non-prd/terraform.tfvars"
terraform apply -var-file="environments/non-prd/terraform.tfvars"

# PRD
terraform plan -var-file="environments/prd/terraform.tfvars"
terraform apply -var-file="environments/prd/terraform.tfvars"
```

### 5. Acessar VM

```bash
terraform output vm_public_ip
ssh -i ~/.ssh/azure_vm_key azureuser@<IP>
```

## Modulos Disponiveis

- **vnet** - Virtual Network
- **subnet** - Subnet
- **nsg** - Network Security Group
- **ssh** - SSH Security Rule
- **vm-linux** - Linux Virtual Machine

Veja detalhes em [`docs/README.md`](docs/README.md)

## Proximos Passos

- [ ] Adicionar backend remoto (Azure Storage)
- [ ] Configurar pipelines CI/CD
- [ ] Adicionar mais modulos
- [ ] Implementar testes automatizados
