# Backend and State Files - Administration Guide

## What It Is

**Backend**: Where Terraform stores the state (state file) of created resources.

**State File**: JSON file that maps your Terraform resources to real resources in Azure.

## Architecture

```
Azure Storage Account: stterraformstate
├── Resource Group: rg-terraform-state
├── Container: terraform-state-prd
│   ├── project-a/terraform.tfstate
│   ├── project-b/terraform.tfstate
│   └── project-c/terraform.tfstate
├── Container: terraform-state-qlt
│   └── (mesma estrutura)
└── Container: terraform-state-tst
    └── (same structure)
```

## Initial Configuration

### 1. Create Backend Infrastructure

```bash
# Run once
cd scripts/setup
./configure-azure-backend.sh

# Result:
# - Resource Group: rg-terraform-state
# - Storage Account: stterraformstate
# - Containers: terraform-state-prd, terraform-state-qlt, terraform-state-tst
```

### 2. Create Service Principals

```bash
# Create SPs for each environment
./create-service-principals.sh

# Result:
# - sp-terraform-prd (Contributor)
# - sp-terraform-qlt (Contributor)
# - sp-terraform-tst (Contributor)
# - Credentials saved in .credentials/
```

### 3. Configure Credentials

```bash
# View generated credentials
cat .credentials/jenkins-credentials.txt

# Add to Jenkins or export locally
export ARM_CLIENT_ID="sp-client-id"
export ARM_CLIENT_SECRET="sp-secret"
export ARM_TENANT_ID="tenant-id"
export ARM_SUBSCRIPTION_ID="subscription-id"
```

## How It Works

### Dynamic Backend

Each project uses empty backend.tf:

```hcl
terraform {
  backend "azurerm" {
    # Configured dynamically by scripts
  }
}
```

Scripts inject values at runtime:

```bash
# Script creates backend-config.tfbackend
resource_group_name  = "rg-terraform-state"
storage_account_name = "stterraformstate"
container_name       = "terraform-state-prd"
key                  = "my-project/terraform.tfstate"

# Terraform init uses this file
terraform init -backend-config=backend-config.tfbackend
```

### State Organization

Rule: One state file per project per environment

```
projeto-a em TST: terraform-state-tst/projeto-a/terraform.tfstate
projeto-a em PRD: terraform-state-prd/projeto-a/terraform.tfstate
projeto-b em PRD: terraform-state-prd/projeto-b/terraform.tfstate
```

## Security

### Access by Environment

- **PRD**: Only CI/CD pipeline and SRE
- **QLT**: Developers + Pipeline
- **TST**: All developers

### Service Principals

Each environment has its own SP:
- sp-terraform-prd: PRD only
- sp-terraform-qlt: QLT only
- sp-terraform-tst: TST only

### Protections

- Soft delete: 30 days
- Versioning: Enabled
- TLS 1.2 minimum
- Public access: Disabled

## Common Operations

### View State File

```bash
# Download state
terraform state pull > current-state.json

# View resources
terraform state list

# View resource details
terraform state show azurerm_resource_group.main
```

### Manual Backup

```bash
# States have automatic versioning in Azure
# For manual backup:
terraform state pull > backup-$(date +%Y%m%d).json
```

### Restore State

```bash
# List available versions
az storage blob list \
  --account-name stterraformstate \
  --container-name terraform-state-prd \
  --prefix my-project/ \
  --include v

# Download specific version
az storage blob download \
  --account-name stterraformstate \
  --container-name terraform-state-prd \
  --name my-project/terraform.tfstate \
  --version-id <version-id> \
  --file terraform.tfstate.backup
```

### Release Locked Lock

```bash
# If state is locked
terraform force-unlock <LOCK_ID>

# LOCK_ID appears in error
```

### Move Resource in State

```bash
# Rename resource in state
terraform state mv azurerm_resource_group.old azurerm_resource_group.new

# Remove resource from state (without destroying)
terraform state rm azurerm_resource_group.test
```

### Import Existing Resource

```bash
# Resource created outside Terraform
terraform import azurerm_resource_group.main /subscriptions/{sub-id}/resourceGroups/rg-name
```

## Troubleshooting

### Corrupted State

```bash
# 1. Check previous versions
az storage blob list --include v ...

# 2. Restore previous version
az storage blob download --version-id ...

# 3. Validate restored state
terraform plan
```

### Stuck Lock

```bash
# Cause: Interrupted pipeline or network
# Solution:
terraform force-unlock <LOCK_ID>
```

### Inconsistent State

```bash
# Resource exists in Azure but not in state
terraform import ...

# Resource in state but doesn't exist in Azure
terraform state rm ...
```

### Inaccessible Backend

```bash
# Check credentials
az login
az account show

# Test storage access
az storage blob list \
  --account-name stterraformstate \
  --container-name terraform-state-tst
```

## Monitoring

### Important Metrics

```bash
# State file sizes
az storage blob list \
  --account-name stterraformstate \
  --container-name terraform-state-prd \
  --query "[].{Name:name, Size:properties.contentLength}"

# Last modified
az storage blob show \
  --account-name stterraformstate \
  --container-name terraform-state-prd \
  --name my-project/terraform.tfstate \
  --query "properties.lastModified"
```

### Recommended Alerts

- State modified in PRD outside hours
- Lock duration > 15 minutes
- State file > 10 MB
- Access failures

## Boas Praticas

### Fazer

- Sempre usar backend remoto
- Um state por projeto
- Testar em TST antes de PRD
- Revisar planos antes de apply
- Manter credenciais seguras
- Usar CI/CD para PRD

### Evitar

- Editar state manualmente
- Compartilhar state entre projetos
- Force-unlock sem investigar
- State local em time
- Commit de state no Git
- Simultaneous applies on same state

## Maintenance

### Daily

- Monitor pipelines
- Check alerts

### Weekly

- Review state sizes
- Verify backups (versioning)
- Clean up states from discontinued projects

### Monthly

- Access audit
- Review permissions
- Test recovery procedures

## Contacts

- **SRE Team**: Backend issues
- **Platform Engineering**: Setup questions
- **Security**: Credential issues

## References

- Project template: terraform-project-template/
- Setup scripts: scripts/setup/
- Deploy scripts: scripts/deployment/
