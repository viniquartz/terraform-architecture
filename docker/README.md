# Docker Build and Test Guide

## Quick Start

### Build the Docker Image

```bash
cd docker/
docker build -t jenkins-terraform-agent:latest .
```

### Test Locally

```bash
# Run container interactively
docker run -it --rm \
  -e ARM_CLIENT_ID="your-client-id" \
  -e ARM_CLIENT_SECRET="your-client-secret" \
  -e ARM_SUBSCRIPTION_ID="your-subscription-id" \
  -e ARM_TENANT_ID="your-tenant-id" \
  jenkins-terraform-agent:latest bash

# Inside container, test Azure authentication
az login --service-principal \
  -u $ARM_CLIENT_ID \
  -p $ARM_CLIENT_SECRET \
  --tenant $ARM_TENANT_ID

# Test Terraform
terraform version

# Exit container
exit
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
