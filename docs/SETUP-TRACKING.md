# Terraform Azure - Setup Guide

## 1. Azure Backend

### Create Storage Account

```bash
LOCATION="westeurope"
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="stterraformstate"

az login

az group create --name $RESOURCE_GROUP --location $LOCATION

az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_GRS \
  --https-only true \
  --min-tls-version TLS1_2

az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT \
  --enable-versioning true

for ENV in prd qlt tst; do
  az storage container create \
    --name terraform-state-$ENV \
    --account-name $STORAGE_ACCOUNT \
    --auth-mode login
done
```

### Create Service Principals

```bash
# Get Subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Service Principal for PRD
echo "=== Creating SP for PRD ==="
az ad sp create-for-rbac \
  --name "sp-terraform-prd" \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --output json > sp-prd.json

cat sp-prd.json
#  SAVE AS SECRET: appId, password, tenant

# Service Principal for QLT
echo "=== Creating SP for QLT ==="
az ad sp create-for-rbac \
  --name "sp-terraform-qlt" \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --output json > sp-qlt.json

cat sp-qlt.json

# Service Principal for TST
echo "=== Creating SP for TST ==="
az ad sp create-for-rbac \
  --name "sp-terraform-tst" \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --output json > sp-tst.json

cat sp-tst.json

#  DELETE THE JSON FILES AFTER SAVING THE CREDENTIALS!
rm sp-*.json
```

**Note**:
```
PRD:
  client_id: _______________
  client_secret: _______________
  tenant_id: _______________
  subscription_id: _______________

QLT:
  client_id: _______________
  client_secret: _______________
  tenant_id: _______________
  subscription_id: _______________

TST:
  client_id: _______________
  client_secret: _______________
  tenant_id: _______________
  subscription_id: _______________
```

### 1.3 - Grant Storage Permissions to SPs

```bash
# For each Service Principal, grant storage access permission

# PRD
SP_PRD_ID=$(az ad sp list --display-name "sp-terraform-prd" --query [0].id -o tsv)
az role assignment create \
  --assignee $SP_PRD_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT/blobServices/default/containers/terraform-state-prd"

# QLT
SP_QLT_ID=$(az ad sp list --display-name "sp-terraform-qlt" --query [0].id -o tsv)
az role assignment create \
  --assignee $SP_QLT_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT/blobServices/default/containers/terraform-state-qlt"

# TST
SP_TST_ID=$(az ad sp list --display-name "sp-terraform-tst" --query [0].id -o tsv)
az role assignment create \
  --assignee $SP_TST_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT/blobServices/default/containers/terraform-state-tst"
```

**Checkpoint**: Each SP has access only to its specific container

---

## PART 2: Docker Image

### 2.1 - Build Image (Optimized multi-stage)

```bash
cd docker/

# Build
docker build -t jenkins-terraform-agent:1.0 .

# Check size
docker images | grep jenkins-terraform-agent

# Test
docker run -it --rm jenkins-terraform-agent:1.0 bash

# Inside container, test:
git --version
az version
terraform version
trivy --version
infracost --version
java -version
```

**Improvements implemented**:
- **Multi-stage build** - reduces final image size (~30-40%)
- **--no-install-recommends** - removes unnecessary packages
- **openjdk-17-jre-headless** - JRE instead of full JDK
- **Optimized layers** - better cache usage
- **Commented validations** - remove after testing

**What to delete later**:
In the Dockerfile, after confirming everything works, **delete** the block:
```dockerfile
# ==============================================================================
# VALIDATION SECTION - DELETE AFTER TESTING
...
# END VALIDATION SECTION
# ==============================================================================
```

This will save more space (removes echoes and validations).

### 2.2 - Push to Registry

```bash
# Option A: Docker Hub
docker tag jenkins-terraform-agent:1.0 your-user/jenkins-terraform-agent:1.0
docker push your-user/jenkins-terraform-agent:1.0

# Option B: Azure Container Registry
az acr login --name myregistry
docker tag jenkins-terraform-agent:1.0 myregistry.azurecr.io/jenkins-terraform-agent:1.0
docker push <registry>/terraform-agent:1.0.0
```

**Checkpoint**: Image available in chosen registry

---

## PART 3: Git Repositories

# Option C: GitLab Container Registry
docker login registry.gitlab.com
docker tag jenkins-terraform-agent:1.0 registry.gitlab.com/yourgroup/jenkins-terraform-agent:1.0
docker push registry.gitlab.com/yourgroup/jenkins-terraform-agent:1.0
```

**Checkpoint**: Image available in chosen registry

---

## PART 3: Git Repositories

### Strategy: 2 Separate Repositories

**Why 2 repos?**
- Separation of responsibilities
- Independent versioning
- Focused CI/CD

#### Repo 1: terraform-azure-project
- **Purpose**: Documentation, templates, pipelines, scripts
- **Versioning**: NO tags (free evolution)
- **Usage**: Reference and setup

#### Repo 2: terraform-azure-modules
- **Purpose**: Versioned Terraform modules
- **Versioning**: Semantic Versioning (v1.0.0, v1.1.0, etc)
- **Usage**: Production (referenced in projects)

### 3.1 - Create terraform-azure-project Repository

```bash
# In GitLab, create empty repository: terraform-azure-project

# Local
cd /path/to/terraform-azure-project
git init
git remote add origin git@gitlab.com:yourgroup/terraform-azure-project.git
git add .
git commit -m "Initial commit: Documentation and templates"
git push -u origin main
```

### 3.2 - Create terraform-azure-modules Repository

```bash
# In GitLab, create empty repository: terraform-azure-modules

# Prepare structure
mkdir terraform-azure-modules
cd terraform-azure-modules

# Copy modules
cp -r ../terraform-azure-project/terraform-modules modules/

# Create README.md
cat > README.md <<EOF
# Terraform Azure Modules

Versioned Terraform modules for Azure.

## Usage

\`\`\`hcl
module "vnet" {
  source = "git@gitlab.com:yourgroup/terraform-azure-modules.git//modules/vnet?ref=v1.0.0"
  
  vnet_name           = "my-vnet"
  location            = "West Europe"
  resource_group_name = "my-rg"
  address_space       = ["10.0.0.0/16"]
  
  tags = {
    Environment = "Production"
  }
}
\`\`\`

## Versions

See [CHANGELOG.md](CHANGELOG.md)
EOF

# Create CHANGELOG.md
cat > CHANGELOG.md <<EOF
# Changelog

## [1.0.0] - $(date +%Y-%m-%d)
### Added
- Initial release
- Modules: vnet, subnet, nsg, ssh, vm-linux, nsg-rules
- Complete validations
- Documentation with terraform-docs
EOF

# Commit and tag
git init
git add .
git commit -m "Initial commit: Terraform Azure modules v1.0.0"
git tag -a v1.0.0 -m "Release v1.0.0 - Initial production release"

# Push
git remote add origin git@gitlab.com:yourgroup/terraform-azure-modules.git
git push -u origin main
git push origin v1.0.0
```

**Checkpoint**: 2 repositories created and first tag v1.0.0 in modules repo

---

## PART 4: Jenkins Configuration
```

**Checkpoint**: 2 repositories created and first tag v1.0.0 in modules repo

---

## PART 4: Jenkins Setup

### 4.1 - Configure Credentials in Jenkins

```
Jenkins > Manage Jenkins > Credentials > System > Global credentials
```

Create the following credentials (type: Secret text):

**PRD**:
- ID: `azure-sp-prd-client-id` → appId value
- ID: `azure-sp-prd-client-secret` → password value
- ID: `azure-sp-prd-subscription-id` → subscription ID
- ID: `azure-sp-prd-tenant-id` → tenant ID

**QLT**:
- ID: `azure-sp-qlt-client-id`
- ID: `azure-sp-qlt-client-secret`
- ID: `azure-sp-qlt-subscription-id`
- ID: `azure-sp-qlt-tenant-id`

**TST**:
- ID: `azure-sp-tst-client-id`
- ID: `azure-sp-tst-client-secret`
- ID: `azure-sp-tst-subscription-id`
- ID: `azure-sp-tst-tenant-id`

**Others**:
- ID: `gitlab-token` → GitLab Personal Access Token
- ID: `teams-webhook-url` → Teams Webhook URL
- ID: `dynatrace-api-token` → Dynatrace API Token
- ID: `dynatrace-api-url` → Dynatrace API URL

### 4.2 - Configure Docker Cloud

```
Jenkins > Manage Jenkins > Clouds > New cloud

Name: docker-agents
Type: Docker

Docker Host URI: unix:///var/run/docker.sock
Enabled: 

Docker Agent Template:
  Labels: terraform-azure-agent
  Name: terraform-azure-agent
  Docker Image: jenkins-terraform-agent:1.0  (or your registry)
  Remote File System Root: /home/jenkins
  Connect method: Attach Docker container
  User: jenkins
  Pull strategy: Pull once and update latest
```

### 4.3 - Create Validation Pipeline

```
Jenkins > New Item
Name: terraform-validation
Type: Pipeline

Pipeline script from SCM:
  SCM: Git
  Repository URL: git@gitlab.com:yourgroup/terraform-azure-modules.git
  Credentials: gitlab-token
  Branch: */main
  Script Path: pipelines/terraform-validation-pipeline.groovy
```

### 4.4 - Create Deploy Pipeline

```
Jenkins > New Item
Name: terraform-deploy
Type: Pipeline

Parameters:
  - ENVIRONMENT: Choice (prd, qlt, tst)
  - PROJECT_NAME: String
  - ACTION: Choice (plan, apply, destroy)

Pipeline script from SCM:
  SCM: Git
  Repository URL: git@gitlab.com:yourgroup/terraform-azure-project.git
  Credentials: gitlab-token
  Branch: */main
  Script Path: pipelines/terraform-deploy-pipeline.groovy
```

**Checkpoint**: Jenkins configured with Docker agent and 2 pipelines

---

## PART 5: Using Backend in Projects

### Configuration in Terraform Projects

**providers.tf**:
```hcl
terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "terraform-backend-rg"
    storage_account_name = "terraformstatestorage"
    container_name       = "terraform-state-prd"  # ou qlt, tst
    key                  = "power-bi/terraform.tfstate"  # nome do projeto
  }
}

provider "azurerm" {
  features {}
  # Credentials come from env vars:
  # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID
}
```

### Using Versioned Modules

**main.tf**:
```hcl
module "vnet" {
  source = "git@gitlab.com:yourgroup/terraform-azure-modules.git//modules/vnet?ref=v1.0.0"
  
  vnet_name           = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  
  tags = {
    Environment = var.environment
    Project     = "power-bi"  # or digital-cabin, projeto-X, etc
    ManagedBy   = "Terraform"
  }
}

module "subnet" {
  source = "git@gitlab.com:yourgroup/terraform-azure-modules.git//modules/subnet?ref=v1.0.0"
  
  subnet_name          = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = module.vnet.vnet_name
  address_prefixes     = var.subnet_address_prefixes
}
```

### Manual Deploy (Test)

```bash
# Export credentials for desired environment
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_SUBSCRIPTION_ID="..."
export ARM_TENANT_ID="..."

# Login Azure
az login --service-principal \
  -u $ARM_CLIENT_ID \
  -p $ARM_CLIENT_SECRET \
  --tenant $ARM_TENANT_ID

# Terraform
terraform init
terraform plan
terraform apply
```

**Checkpoint**: State file created in Azure Storage

---

## PART 6: Final Validation

### 6.1 - Verify State in Azure

```bash
# List states
az storage blob list \
  --account-name terraformstatestorage \
  --container-name terraform-state-prd \
  --auth-mode login \
  --output table

# View state content
az storage blob download \
  --account-name terraformstatestorage \
  --container-name terraform-state-prd \
  --name "power-bi/terraform.tfstate" \
  --file /tmp/state.json \
  --auth-mode login

cat /tmp/state.json | jq '.version'
```

### 6.2 - Test State Locking

```bash
# Terminal 1
terraform plan
# (leave it running...)

# Terminal 2
terraform plan
# Should fail with: Error acquiring the state lock
```

### 6.3 - Run Pipeline in Jenkins

```
Jenkins > terraform-deploy > Build with Parameters

ENVIRONMENT: qlt
PROJECT_NAME: power-bi  # or digital-cabin, projeto-X
ACTION: plan

[Build]
```

Verify:
- Docker agent starts
- Code checkout
- Terraform init OK
- Terraform plan OK
- Teams notification (if configured)

**Note**: Each project (power-bi, digital-cabin, projeto-X) has its own specific Terraform architecture

---

## Quick References

### Backend Config por Ambiente

```bash
# PRD
container_name = "terraform-state-prd"

# QLT
container_name = "terraform-state-qlt"

# TST
container_name = "terraform-state-tst"
```

### Module Versioning

```hcl
# Use specific version
?ref=v1.0.0

# Update version
?ref=v1.1.0
```

### Useful Commands

```bash
# View module versions
git ls-remote --tags git@gitlab.com:yourgroup/terraform-azure-modules.git

# State locking force unlock (CAREFUL!)
terraform force-unlock LOCK_ID

# Download state
terraform state pull > backup.tfstate

# Upload state
terraform state push backup.tfstate

# View resources in state
terraform state list

# View resource details
terraform state show azurerm_virtual_network.this
```

---

## Troubleshooting

### Problem: Docker image too large

**Solution**: After validating it works, delete VALIDATION section from Dockerfile and rebuild:
```bash
# Remove lines 112-122 from Dockerfile (verification section)
docker build -t jenkins-terraform-agent:1.0 .
```

### Problem: State lock not releasing

**Solution**:
```bash
# Wait 15 seconds (lock expires automatically)
sleep 20

# Or force unlock (only if you're sure!)
terraform force-unlock LOCK_ID
```

### Problem: Permission denied on Storage

**Solution**:
```bash
# Check SP permissions
az role assignment list \
  --assignee $ARM_CLIENT_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/terraform-backend-rg"

# Add permission if needed
az role assignment create \
  --assignee $ARM_CLIENT_ID \
  --role "Storage Blob Data Contributor" \
  --scope "..."
```

---

## Final Checklist

Before considering complete:

**Azure**:
- [ ] Storage Account created
- [ ] 3 containers created (prd, qlt, tst)
- [ ] 3 Service Principals created
- [ ] RBAC permissions configured
- [ ] Versioning enabled
- [ ] Soft delete enabled

**Git**:
- [ ] terraform-azure-project created
- [ ] terraform-azure-modules created
- [ ] Tag v1.0.0 created
- [ ] Branch protection configured

**Jenkins**:
- [ ] Docker image built
- [ ] 12+ credentials registered
- [ ] Docker cloud configured
- [ ] 2 pipelines created

**Validation**:
- [ ] Manual deploy worked
- [ ] State no Azure Storage
- [ ] State locking OK
- [ ] Jenkins pipeline OK

---

## Final Notes

**Docker Compose**: Removed - not necessary. Was only used for initial local testing. Use `docker run` directly or Jenkins.

**Multi-stage**: Implemented - reduces image from ~1.2GB to ~800MB.

**Backend**: 1 container per environment (prd/qlt/tst) with projects inside as keys.

**Documentation**: This document will be converted to final docs after completion and full setup validation.

---

**Last update**: 2025-12-04
**Status**: Under construction
