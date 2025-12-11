# Jenkins Agent Docker Image

Optimized Jenkins image with Terraform and essential tools.

## Available Versions

### Optimized Version (Recommended) - ~300-400MB
```bash
docker build -t jenkins-terraform:optimized .
```

Includes:
- Terraform 1.5.7
- TFSec 1.28.4
- Git, curl
- Java 17 JRE
- Bash

## Build

```bash
# Optimized version (recommended)
docker build -t jenkins-terraform:latest .

# View size
docker images jenkins-terraform:latest
```

## Usage

```bash
# Test locally
docker run -it jenkins-terraform:latest bash

# Verify tools
docker run jenkins-terraform:latest terraform version
docker run jenkins-terraform:latest tfsec --version
```

## Jenkins Configuration

Configure in Jenkins (Manage Jenkins > Clouds):

```groovy
dockerTemplate {
    image 'jenkins-terraform:latest'
    label 'terraform-agent'
}
```

## Size Reduction

From 2GB to 300-400MB:
- Base Ubuntu -> Alpine Linux
- Removed Checkov (rarely used)
- Removed terraform-docs (optional)
- Removed Azure CLI (use provider auth)
- Removed Python dependencies

## Customization

Edit Dockerfile to:
- Add/remove tools
- Adjust versions
- Modify Jenkins user

##  Quick Start

### 1. Build the Image

```bash
cd docker/
docker build -t jenkins-terraform-agent:1.0 .

# Build with custom versions
docker build \
  --build-arg TERRAFORM_VERSION=1.6.0 \
  --build-arg TFSEC_VERSION=1.28.5 \
  -t jenkins-terraform-agent:1.0 .
```

### 2. Test Locally

```bash
# Run container interactively
docker run -it --rm \
  -e ARM_CLIENT_ID="your-sp-client-id" \
  -e ARM_CLIENT_SECRET="your-sp-secret" \
  -e ARM_SUBSCRIPTION_ID="your-subscription-id" \
  -e ARM_TENANT_ID="your-tenant-id" \
  jenkins-terraform-agent:1.0 bash

# Inside container - verify tools
git --version
az version
terraform version
tfsec --version
checkov --version
terraform-docs --version
python3 --version
java -version

# Test Azure authentication
az login --service-principal \
  -u $ARM_CLIENT_ID \
  -p $ARM_CLIENT_SECRET \
  --tenant $ARM_TENANT_ID

az account show

# Exit
exit
```

### 3. Push to Registry

#### Option A: Docker Hub

```bash
docker tag jenkins-terraform-agent:1.0 yourusername/jenkins-terraform-agent:1.0
docker login
docker push yourusername/jenkins-terraform-agent:1.0
```

#### Option B: Azure Container Registry

```bash
# Login
az acr login --name myregistry

# Tag and push
docker tag jenkins-terraform-agent:1.0 myregistry.azurecr.io/jenkins-terraform-agent:1.0
docker push myregistry.azurecr.io/jenkins-terraform-agent:1.0
```

#### Option C: GitLab Container Registry

```bash
# Login
docker login registry.gitlab.com

# Tag and push
docker tag jenkins-terraform-agent:1.0 registry.gitlab.com/yourgroup/jenkins-terraform-agent:1.0
docker push registry.gitlab.com/yourgroup/jenkins-terraform-agent:1.0
```

## 🔧 Jenkins Configuration

### Docker Cloud Setup

```
Jenkins > Manage Jenkins > Clouds > New cloud

Cloud Details:
  Name: docker-agents
  Type: Docker
  Docker Host URI: unix:///var/run/docker.sock

Docker Agent Template:
  Labels: terraform-azure-agent
  Name: terraform-azure-agent
  Docker Image: jenkins-terraform-agent:1.0
  Remote File System Root: /home/jenkins
  Connect method: Attach Docker container
  User: jenkins
  Pull strategy: Pull once and update latest
```

### Credentials Configuration

Add these credentials in Jenkins (Secret text type):

**Per Environment (prd/qlt/tst)**:
- `azure-sp-{env}-client-id`
- `azure-sp-{env}-client-secret`
- `azure-sp-{env}-subscription-id`
- `azure-sp-{env}-tenant-id`

### Pipeline Example

```groovy
pipeline {
  agent {
    label 'terraform-azure-agent'
  }
  
  environment {
    ARM_CLIENT_ID = credentials('azure-sp-prd-client-id')
    ARM_CLIENT_SECRET = credentials('azure-sp-prd-client-secret')
    ARM_SUBSCRIPTION_ID = credentials('azure-sp-prd-subscription-id')
    ARM_TENANT_ID = credentials('azure-sp-prd-tenant-id')
  }
  
  stages {
    stage('Terraform Init') {
      steps {
        sh 'terraform init'
      }
    }
    
    stage('Terraform Plan') {
      steps {
        sh 'terraform plan'
      }
    }
  }
}
```

## 🎨 Customization

### Build Arguments

Available build arguments:

```dockerfile
ARG TERRAFORM_VERSION=1.5.7
ARG TFSEC_VERSION=1.28.4
ARG TERRAFORM_DOCS_VERSION=0.17.0
ARG JENKINS_USER=jenkins
ARG JENKINS_UID=1000
ARG JENKINS_GID=1000
```

### Custom Build Example

```bash
docker build \
  --build-arg TERRAFORM_VERSION=1.6.0 \
  --build-arg TFSEC_VERSION=1.28.5 \
  --build-arg JENKINS_UID=2000 \
  -t jenkins-terraform-agent:custom .
```

##  Post-Validation Cleanup

After confirming the image works in Jenkins, remove the validation section from Dockerfile:

**Delete lines 107-119** (between VALIDATION SECTION comments)

This saves ~50MB and removes unnecessary output during builds.

```bash
# Edit Dockerfile, remove validation section
vim Dockerfile

# Rebuild optimized image
docker build -t jenkins-terraform-agent:1.0 .
```

## 🐛 Troubleshooting

### Image size too large

 **Solution**: Multi-stage build already implemented (~800MB vs ~1.2GB)
- Remove validation section after testing
- Use `--no-install-recommends` (already in place)
- JRE instead of JDK (already in place)

### Tool version mismatch

 **Solution**: Use build arguments to specify versions

```bash
docker build --build-arg TERRAFORM_VERSION=1.6.0 -t jenkins-terraform-agent:1.0 .
```

### Permission issues in Jenkins

 **Solution**: Match Jenkins UID/GID

```bash
# Find Jenkins UID/GID on host
id jenkins

# Rebuild with matching UID/GID
docker build \
  --build-arg JENKINS_UID=1001 \
  --build-arg JENKINS_GID=1001 \
  -t jenkins-terraform-agent:1.0 .
```

### Azure CLI authentication fails

 **Solution**: Verify Service Principal credentials

```bash
# Test SP manually
az login --service-principal \
  -u <client-id> \
  -p <client-secret> \
  --tenant <tenant-id>

# Verify permissions
az account show
az role assignment list --assignee <client-id>
```

## Image Layers

The multi-stage build creates two stages:

**Stage 1 (builder)**: Downloads binaries
- Terraform zip
- TFSec binary
- terraform-docs binary
- Discarded after build

**Stage 2 (final)**: Runtime image
- Ubuntu 22.04 base
- Runtime dependencies only
- Copied binaries from builder
- User setup (non-root)

##  Security Features

-  Non-root user (jenkins)
-  No passwords stored in image
-  Minimal attack surface (no build tools)
-  TLS 1.2+ only for Azure CLI
-  No secrets in layers

##  References

- Dockerfile: [Dockerfile](Dockerfile)
- Setup Guide: [docs/SETUP-TRACKING.md](../docs/SETUP-TRACKING.md)
- Pipelines: [pipelines/](../pipelines/)

---

**Last Updated**: December 2025  
**Maintained By**: Platform Engineering Team
