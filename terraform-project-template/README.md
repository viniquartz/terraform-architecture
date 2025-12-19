# Terraform Project Template

Standard template for Terraform Azure projects using shared modules and centralized pipelines.

## Table of Contents

- [What's Included](#whats-included)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Testing Scenarios](#testing-scenarios)
- [What to Customize](#what-to-customize)
- [Helper Scripts](#helper-scripts)
- [Troubleshooting](#troubleshooting)
- [Reference](#reference)

## What's Included

```text
terraform-project-template/
├── backend.tf               # Dynamic backend configuration
├── providers.tf             # Azure provider (azurerm ~> 3.0)
├── variables.tf             # Environment, project, location variables
├── main.tf                  # Example infrastructure using modules
├── outputs.tf               # Standard outputs
├── terraform.tfvars.example # Example variables file
├── scripts/
│   ├── init-backend.sh      # Initialize Terraform backend
│   └── deploy.sh            # Complete deployment workflow
└── .gitignore               # Security-focused ignore rules
```

## Architecture

This template demonstrates:

- **Naming Convention**: `azr_<env>_<project><version>_<region>_<resource>[suffix]`
- **Networking**: VNet with multiple subnets (app, data)
- **Security**: NSG with custom security rules
- **Storage**: Storage Account with containers
- **Optional**: VM and ACR modules (commented out by default)

All resources use shared modules from `terraform-azure-modules` repository.

Example naming output:

- Resource Group: `azr_tst_myapp01_brs_rg`
- Virtual Network: `azr_tst_myapp01_brs_vnet`
- Storage Account: `azrtstmyapp01brsst`

## Prerequisites

- Azure CLI installed and authenticated
- Terraform >= 1.5.0 installed
- Service Principal credentials (from `create-service-principals.sh`)
- Backend configured (from `configure-azure-backend.sh`)
- Git SSH access configured (for module sources)

## Quick Start

### 1. Copy Template

```bash
# Create new project directory
mkdir -p ~/projects/my-terraform-project
cd ~/projects/my-terraform-project

# Copy template files
cp -r /path/to/terraform-project-template/* .
```

### 2. Configure Variables

```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

Example `terraform.tfvars`:

```hcl
environment  = "tst"
project_name = "myapp"
location     = "brazilsouth"

# Optional: If using VM module, uncomment and add SSH key
# admin_ssh_key = "ssh-rsa AAAAB3Nza..."
```

### 3. Configure Backend

Create `backend-config.tfbackend`:

```hcl
resource_group_name  = "rg-terraform-backend"
storage_account_name = "sttfbackend<unique>"  # From configure-azure-backend.sh output
container_name       = "terraform-state-tst"
key                  = "myapp.tfstate"
```

### 4. Set Azure Credentials

```bash
# Service Principal credentials
export ARM_CLIENT_ID="<sp-client-id>"
export ARM_CLIENT_SECRET="<sp-client-secret>"
export ARM_TENANT_ID="<tenant-id>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"
```

### 5. Deploy Infrastructure

**Option A: Using Helper Scripts**

```bash
chmod +x scripts/*.sh

# Initialize backend
./scripts/init-backend.sh myapp tst

# Deploy infrastructure
./scripts/deploy.sh myapp tst
```

**Option B: Manual Terraform Commands**

```bash
# Initialize
terraform init -backend-config=backend-config.tfbackend

# Validate
terraform validate

# Plan
terraform plan

# Apply
terraform apply

# Destroy
terraform destroy
```

## Testing Scenarios

### Scenario 1: Basic Infrastructure (Default)

Tests naming module, VNet, NSG, and Storage.

**Steps:**

1. Use default `main.tf` (VM and ACR commented out)
2. Follow Quick Start steps 1-5
3. Verify 6 resources created

**Expected Resources:**

- Resource Group: `azr_tst_myapp01_brs_rg`
- Virtual Network: `azr_tst_myapp01_brs_vnet`
- Subnets: `azr_tst_myapp01_brs_snet_app`, `azr_tst_myapp01_brs_snet_data`
- NSG: `azr_tst_myapp01_brs_nsg`
- Storage Account: `azrtstmyapp01brsst`
- Storage Containers: `data`, `logs`

**Verification:**

```bash
# List all resources
az resource list --resource-group azr_tst_myapp01_brs_rg --output table

# Check Storage Account
az storage account show \
  --name azrtstmyapp01brsst \
  --resource-group azr_tst_myapp01_brs_rg

# Check Virtual Network
az network vnet show \
  --name azr_tst_myapp01_brs_vnet \
  --resource-group azr_tst_myapp01_brs_rg
```

**Cleanup:**

```bash
terraform destroy
```

### Scenario 2: With Virtual Machine

Tests VM module integration.

**Steps:**

1. Generate SSH key:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/terraform_test
```

2. Add SSH key to `terraform.tfvars`:

```hcl
admin_ssh_key = "ssh-rsa AAAAB3..."
```

3. Uncomment VM module section in `main.tf`
4. Uncomment `admin_ssh_key` variable in `variables.tf`
5. Run `terraform apply`

**Expected Additional Resources:** VM, NIC (+2 resources)

**Cleanup:**

```bash
terraform destroy
```

### Scenario 3: With Container Registry

Tests ACR module integration.

**Steps:**

1. Uncomment ACR module section in `main.tf`
2. Run `terraform apply`
3. Test login: `az acr login --name azrtstmyapp01brsacr`

**Expected Additional Resources:** ACR (+1 resource)

### Scenario 4: Multiple Instances with Count

Tests naming convention with multiple resources.

**Steps:**

1. Modify `main.tf` to create 3 VMs:

```hcl
module "vm" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/vm?ref=v1.0.0"
  count  = 3
  
  name                = "${module.naming.virtual_machine}${format("%02d", count.index + 1)}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  vm_size             = "Standard_B2s"
  subnet_id           = module.vnet.subnet_ids["app"]
  admin_ssh_key       = var.admin_ssh_key
  
  tags = local.common_tags
}
```

2. Run `terraform apply`

**Expected Resources:** 3 VMs named `azr_tst_myapp01_brs_vm01`, `02`, `03`

### Scenario 5: Different Environments

Tests environment-specific naming.

**Steps:**

1. Test TST environment (Quick Start)
2. Change `environment = "qlt"` in `terraform.tfvars`
3. Update backend container: `container_name = "terraform-state-qlt"`
4. Run `terraform init -reconfigure -backend-config=backend-config.tfbackend`
5. Run `terraform apply`

**Verification:** Resources use `azr_qlt_` prefix

## What to Customize

### main.tf

Add your Azure resources. Current example includes:

- Resource Group (required)
- VNet with subnets
- NSG with security rules
- Storage Account
- Optional: VM, ACR (commented out)

### variables.tf

Add project-specific variables. Current variables:

- `environment` (validated: prd, qlt, tst)
- `project_name` (validated: lowercase, numbers, hyphens)
- `location` (default: brazilsouth)
- `admin_ssh_key` (optional, for VMs)

### outputs.tf

Add outputs to expose resource information. Current outputs show IDs and names.

### backend.tf

**DO NOT CHANGE**. Backend configuration is generated dynamically by `init-backend.sh`.

## Helper Scripts

### scripts/init-backend.sh

**Purpose:** Initialize Terraform backend with dynamic configuration.

**Usage:**

```bash
./scripts/init-backend.sh <project-name> <environment>
```

**Example:**

```bash
./scripts/init-backend.sh myapp tst
```

**What it does:**

- Validates project name and environment
- Generates `backend-config.tfbackend` file
- Initializes Terraform with remote state backend
- Reconfigures backend if already initialized

**Note:** Update `STORAGE_ACCOUNT` variable with your actual storage account name from `configure-azure-backend.sh` output.

### scripts/deploy.sh

**Purpose:** Complete deployment workflow (init + plan + apply).

**Usage:**

```bash
./scripts/deploy.sh <project-name> <environment> [--auto-approve]
```

**Example:**

```bash
./scripts/deploy.sh myapp tst
./scripts/deploy.sh myapp prd --auto-approve
```

**What it does:**

- Calls `init-backend.sh` to configure remote state
- Generates Terraform execution plan
- Applies changes to Azure infrastructure
- Provides option for auto-approval (CI/CD usage)

## Backend Storage

State files are stored in Azure Storage:

- **Storage Account**: `sttfbackend<unique>`
- **Resource Group**: `rg-terraform-backend`
- **Container Pattern**: `terraform-state-{environment}`
- **Key Pattern**: `{project-name}.tfstate`

**Examples:**

- TST: `terraform-state-tst/myapp.tfstate`
- QST: `terraform-state-qlt/myapp.tfstate`
- PRD: `terraform-state-prd/myapp.tfstate`

## Useful Commands

```bash
# View outputs
terraform output

# View resources in state
terraform state list

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan with specific variables
terraform plan -var="environment=tst" -var="project_name=myapp"

# Show current state
terraform show

# Refresh state
terraform refresh

# Destroy infrastructure
terraform destroy
```

## Troubleshooting

### Error: Backend not initialized

**Symptom:** `Error: Backend initialization required`

**Solution:**

```bash
./scripts/init-backend.sh <project-name> <environment>
```

### Error: Invalid credentials

**Symptom:** `Error: building account: could not acquire access token`

**Solution:**

```bash
# Check if logged in
az account show

# Or use Service Principal credentials
export ARM_CLIENT_ID="<client-id>"
export ARM_CLIENT_SECRET="<client-secret>"
export ARM_TENANT_ID="<tenant-id>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"

# Test authentication
az login --service-principal \
  -u $ARM_CLIENT_ID \
  -p $ARM_CLIENT_SECRET \
  --tenant $ARM_TENANT_ID
```

### Error: Container does not exist

**Symptom:** `Error: Failed to get existing workspaces: containers.Client#ListBlobs`

**Solution:** Run backend configuration script first:

```bash
cd ../../scripts/setup
./configure-azure-backend.sh
```

### Error: Module source not found

**Symptom:** `Error: Failed to download module`

**Solution:** For local testing, use local module sources:

```hcl
module "naming" {
  source = "../../terraform-modules/modules/naming"
  # ...
}
```

For production, ensure git SSH access is configured:

```bash
# Test SSH access
ssh -T git@github.com

# Add SSH key if needed
ssh-add ~/.ssh/id_rsa
```

### Error: Storage account name invalid

**Symptom:** `The storage account named 'azr_tst_...' is invalid`

**Solution:** Storage names are handled automatically by naming module. Verify naming module is properly configured and removes special characters for storage accounts.

### Error: Resource already exists

**Symptom:** `A resource with the ID already exists`

**Solution:**

```bash
# Option 1: Import existing resource
terraform import azurerm_resource_group.main /subscriptions/<sub-id>/resourceGroups/<rg-name>

# Option 2: Change project name or destroy previous resources
terraform destroy
```

## Reference

### Module Sources

For local development:

```hcl
module "naming" {
  source = "../../terraform-modules/modules/naming"
}
```

For production (with versioning):

```hcl
module "naming" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/naming?ref=v1.0.0"
}
```

### Related Documentation

- **Architecture:** `docs/architecture-plan.md`
- **Modules:** `terraform-modules/README.md`
- **Naming Convention:** `terraform-modules/modules/naming/README.md`
- **Scripts:** `scripts/README.md`
- **Pipelines:** `pipelines/README.md`
- **Troubleshooting:** `docs/troubleshooting.md`

### Support

For issues or questions:

1. Check `docs/troubleshooting.md`
2. Review module README files
3. Consult `scripts/README.md` for setup scripts
4. Check pipeline documentation in `pipelines/README.md`
