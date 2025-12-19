# Terraform Azure CI/CD Framework

Core infrastructure automation framework with Jenkins pipelines and Docker-based CI/CD.

**Note:** Terraform modules and project templates are in separate repositories.

## What This Repository Provides

- **Jenkins Pipelines:** Automated validation, deployment, and drift detection
- **Docker Image:** Jenkins agent with Terraform, Azure CLI, Trivy, Infracost
- **Setup Scripts:** Backend infrastructure and service principal creation
- **POC Scripts:** Manual testing and demonstration workflows

## Quick Start

### For Infrastructure Team

```bash
# 1. Create backend infrastructure
cd scripts/setup
./configure-azure-backend.sh
./create-service-principals.sh

# 2. Build Docker image
cd ../../docker
docker build -t jenkins-terraform:latest .

# 3. Configure Jenkins
# - Install Docker plugin
# - Load shared libraries from pipelines/
# - Add Azure credentials for each environment
```

### For Developers

```bash
# Clone project template from separate repo
git clone git@github.com:org/terraform-project-template.git my-project
cd my-project

# Customize and deploy via Jenkins pipeline
# (Pipeline will use this repo's automation)
```

### For POC Testing

```bash
# 1. Authenticate
cd scripts/poc
export ARM_CLIENT_ID="xxx"
export ARM_CLIENT_SECRET="xxx"
export ARM_SUBSCRIPTION_ID="xxx"
export ARM_TENANT_ID="xxx"
./azure-login.sh

# 2. Configure and deploy
./configure.sh myproject tst /path/to/workspace
./deploy.sh myproject tst /path/to/workspace

# 3. Cleanup
./destroy.sh myproject tst /path/to/workspace --auto-approve --delete-state
```

## Repository Structure

```plaintext
terraform-azure-project/
├── docker/                  # Jenkins agent container
│   ├── Dockerfile          # Alpine + tools (Terraform, Azure CLI, Trivy, Infracost)
│   └── README.md           # Build instructions
├── pipelines/              # Jenkins shared libraries (Groovy)
│   ├── terraform-deploy-pipeline.groovy
│   ├── terraform-validation-pipeline.groovy
│   ├── terraform-modules-validation-pipeline.groovy
│   ├── terraform-drift-detection-pipeline.groovy
│   └── README.md
├── scripts/
│   ├── poc/                # Manual POC scripts
│   ├── setup/              # Backend setup (one-time)
│   └── import/             # Import existing resources
└── docs/                   # Documentation
    ├── FILE-STRUCTURE.md   # Detailed structure
    ├── architecture-plan.md
    ├── BACKEND.md
    └── SETUP.md
```

## Separate Repositories

| Repository | Purpose | Usage |
|------------|---------|-------|
| **terraform-azure-modules** | Reusable modules | Referenced by git source in projects |
| **terraform-project-template** | Project starter | Cloned for new projects |
| **terraform-azure-project** (this) | CI/CD automation | Pipelines and tools |

## Tools Included

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | 1.5.7 | Infrastructure as Code |
| Azure CLI | Latest | Authentication and validation |
| Trivy | 0.48.0 | Security scanning |
| Infracost | 0.10.32 | Cost estimation |

## Environments

| Environment | Backend Container | Service Principal |
|-------------|-------------------|-------------------|
| Production | `terraform-state-prd` | `sp-terraform-prd` |
| Quality | `terraform-state-qlt` | `sp-terraform-qlt` |
| Test | `terraform-state-tst` | `sp-terraform-tst` |

## Documentation

- [Complete Structure](docs/FILE-STRUCTURE.md) - Detailed repository structure
- [Architecture Plan](docs/architecture-plan.md) - Design decisions and patterns
- [Backend Setup](docs/BACKEND.md) - Backend configuration guide
- [Setup Guide](docs/SETUP.md) - Initial setup instructions
- [Docker Image](docker/README.md) - Container build and usage
- [Pipelines](pipelines/README.md) - Jenkins pipeline documentation
- [POC Scripts](scripts/poc/README.md) - Manual testing workflow

## CI/CD Workflow

```
Developer commits → Jenkins pipeline → Docker container → Validation → Deploy
                                     (this repo)        (Trivy, Infracost)
```

1. Code pushed to project repository
2. Jenkins triggers pipeline from `pipelines/`
3. Container spun up from `docker/Dockerfile`
4. Validation: fmt, validate, security scan, cost analysis
5. Plan generated and reviewed
6. Approval gate (production only)
7. Apply executed
8. Notifications sent

## Contributing

### Update Docker Image

```bash
cd docker
# Edit Dockerfile to update versions
docker build -t jenkins-terraform:latest .
docker push <registry>/jenkins-terraform:latest
```

### Update Pipelines

```bash
# Edit pipelines/*.groovy
git commit -m "Update pipeline"
git push
# Jenkins auto-loads from this repo
```

## Support

For questions or issues:
- Pipeline issues: See `pipelines/README.md`
- Backend issues: See `docs/BACKEND.md`
- POC testing: See `scripts/poc/README.md`
- Module usage: See terraform-azure-modules repository
