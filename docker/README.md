# Docker Build and Test Guide

## Quick Start

### Build the Docker Image

```bash
cd docker/
docker build -t jenkins-terraform-agent:latest .
```

### Test Locally with Docker Compose

```bash
# 1. Copy environment template
cp env.example .env

# 2. Edit .env with your credentials
vim .env

# 3. Start container
docker-compose up -d

# 4. Access container
docker-compose exec jenkins-agent bash

# 5. Test Azure authentication
az login --service-principal \
  -u $ARM_CLIENT_ID \
  -p $ARM_CLIENT_SECRET \
  --tenant $ARM_TENANT_ID

# 6. Test Terraform
terraform version

# 7. Stop container
docker-compose down
```

## Verify All Tools

Run inside the container:

```bash
# Check versions
git --version
az --version
terraform version
tfsec --version
checkov --version
terraform-docs --version
python3 --version
java -version

# Test Azure CLI
az account show

# Test Terraform
terraform init
terraform validate
```

## Push to Registry

### Docker Hub

```bash
docker tag jenkins-terraform-agent:latest yourusername/jenkins-terraform-agent:latest
docker push yourusername/jenkins-terraform-agent:latest
```

### Azure Container Registry (ACR)

```bash
# Login to ACR
az acr login --name myregistry

# Tag image
docker tag jenkins-terraform-agent:latest myregistry.azurecr.io/jenkins-terraform-agent:latest

# Push image
docker push myregistry.azurecr.io/jenkins-terraform-agent:latest
```

## Customize Build

Edit Dockerfile ARG values:

```dockerfile
ARG TERRAFORM_VERSION=1.6.0
ARG TFSEC_VERSION=1.28.5
ARG TERRAFORM_DOCS_VERSION=0.17.0
```

Then rebuild:

```bash
docker build \
  --build-arg TERRAFORM_VERSION=1.6.0 \
  --build-arg TFSEC_VERSION=1.28.5 \
  -t jenkins-terraform-agent:custom .
```
