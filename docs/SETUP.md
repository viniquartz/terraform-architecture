# Terraform Azure Setup

## 1. Azure Backend

### Create Infrastructure

```bash
cd scripts/setup
./configure-azure-backend.sh
```

Creates:
- Resource Group: `rg-terraform-state`
- Storage Account: `stterraformstate`
- Containers: `terraform-state-prd`, `terraform-state-qlt`, `terraform-state-tst`

### Create Service Principals

```bash
./create-service-principals.sh
```

Creates:
- `sp-terraform-prd`
- `sp-terraform-qlt`
- `sp-terraform-tst`

Credentials saved in `.credentials/` directory.

## 2. Docker Image

### Build

```bash
cd docker
docker build -t jenkins-terraform:latest .
```

### Test

```bash
docker run -it jenkins-terraform:latest bash
terraform version
trivy --version
infracost --version
az version
```

### Push to Registry

```bash
# Docker Hub
docker tag jenkins-terraform:latest your-user/jenkins-terraform:latest
docker push your-user/jenkins-terraform:latest

# Azure Container Registry
az acr login --name myregistry
docker tag jenkins-terraform:latest myregistry.azurecr.io/jenkins-terraform:latest
docker push myregistry.azurecr.io/jenkins-terraform:latest
```

## 3. Jenkins Configuration

### Add Credentials

In Jenkins: Manage Jenkins → Credentials → Add

For each environment (prd, qlt, tst):
- `azure-sp-{env}-client-id`
- `azure-sp-{env}-client-secret`
- `azure-sp-{env}-subscription-id`
- `azure-sp-{env}-tenant-id`

### Configure Docker Cloud

Jenkins → Manage Jenkins → Clouds → New cloud

```
Name: docker-agents
Type: Docker
Docker Host URI: unix:///var/run/docker.sock

Docker Agent Template:
  Labels: terraform-agent
  Docker Image: jenkins-terraform:latest
  User: jenkins
```

### Create Pipelines

#### Deploy Pipeline

```
Name: terraform-deploy
Type: Pipeline

Parameters:
  - ENVIRONMENT: Choice (prd, qlt, tst)
  - PROJECT_NAME: String
  - ACTION: Choice (plan, apply, destroy)

Script Path: pipelines/terraform-deploy-pipeline.groovy
```

#### Validation Pipeline

```
Name: terraform-validation
Type: MultiBranch Pipeline
Script Path: pipelines/terraform-validation-pipeline.groovy
```

## 4. Using Backend

### Backend Configuration

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "terraform-state-prd"
    key                  = "my-project/terraform.tfstate"
  }
}
```

### Authentication

```bash
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_TENANT_ID="..."
export ARM_SUBSCRIPTION_ID="..."
```

### Deploy

```bash
terraform init
terraform plan
terraform apply
```

## 5. POC Testing

### Setup Environment

```bash
export ARM_CLIENT_ID="..."
export ARM_CLIENT_SECRET="..."
export ARM_TENANT_ID="..."
export ARM_SUBSCRIPTION_ID="..."
```

### Authenticate

```bash
cd scripts/poc
./azure-login.sh
```

### Deploy

```bash
# Configure backend and validate
./configure.sh my-project tst /path/to/workspace

# Deploy resources
./deploy.sh my-project tst /path/to/workspace --auto-approve

# Cleanup
./destroy.sh my-project tst /path/to/workspace --auto-approve --delete-state
```

For project template usage, see separate terraform-project-template repository.

## Useful Commands

```bash
# List state files
az storage blob list \
  --account-name stterraformstate \
  --container-name terraform-state-prd \
  --auth-mode login

# View state
terraform state list
terraform state show <resource>

# Force unlock (if needed)
terraform force-unlock <LOCK_ID>
```
