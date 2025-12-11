# Terraform Azure Framework

Terraform infrastructure framework for Azure with CI/CD pipelines and multi-environment support.

## Quick Start

### 1. Setup Azure Backend

```bash
cd scripts/setup
./configure-azure-backend.sh
./create-service-principals.sh
```

Creates Storage Account with containers (prd/qlt/tst) and Service Principals.

### 2. Use Project Template

```bash
cp -r terraform-project-template/ ../my-project/
cd ../my-project/
./scripts/init-backend.sh
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

## Repository Structure

```
├── docs/                    # Documentation
├── docker/                  # Jenkins agent image
├── pipelines/              # Jenkins pipelines
├── scripts/
│   ├── setup/              # Backend and SP setup
│   └── import/             # Import utilities
└── terraform-project-template/  # Project starter template
```

## Components

**Docker Agent**: Optimized Alpine image (~300-400MB) with Terraform, TFSec, Git, Java 17

**Pipelines**: Deploy, validation, drift detection with security scanning

**Template**: Complete project structure with backend configuration and deployment scripts

## Environments

| Environment | Container | Service Principal |
|------------|-----------|-------------------|
| PRD | terraform-state-prd | sp-terraform-prd |
| QLT | terraform-state-qlt | sp-terraform-qlt |
| TST | terraform-state-tst | sp-terraform-tst |

## Documentation

- [Setup Guide](docs/SETUP.md)
- [Backend Administration](docs/BACKEND.md)
- [Docker Setup](docker/README.md)
- [Pipelines](pipelines/README.md)
