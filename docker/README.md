# Jenkins Agent Docker Image

Optimized Jenkins image with Terraform, Azure CLI, Trivy, and Infracost for CI/CD pipelines.

## Image Details

**Base:** Alpine Linux 3.19  
**Size:** ~500-550MB (optimized)  
**Tools:** Terraform, Azure CLI, Trivy, Infracost, Git, Java 17

## Included Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | 1.5.7 | Infrastructure as Code |
| Azure CLI | Latest | Azure authentication |
| Trivy | 0.48.0 | Security scanning |
| Infracost | 0.10.32 | Cost estimation |
| Git | Latest | Version control |
| OpenJDK 17 | Latest | Jenkins agent |
| Bash | Latest | Script execution |

## Build

```bash
# Build image
cd docker
docker build -t jenkins-terraform:latest .

# View size
docker images jenkins-terraform:latest

# Build with custom versions
docker build \
  --build-arg TERRAFORM_VERSION=1.6.0 \
  --build-arg TRIVY_VERSION=0.49.0 \
  --build-arg INFRACOST_VERSION=0.10.33 \
  -t jenkins-terraform:latest .
```

## Usage

### Test Locally

```bash
# Interactive shell
docker run -it --rm jenkins-terraform:latest bash

# Verify tools
docker run --rm jenkins-terraform:latest bash -c "
  terraform version
  az version --query '\"azure-cli\"' -o tsv
  trivy --version
  infracost --version
"
```

### With Azure Credentials

```bash
docker run -it --rm \
  -e ARM_CLIENT_ID="xxx" \
  -e ARM_CLIENT_SECRET="xxx" \
  -e ARM_SUBSCRIPTION_ID="xxx" \
  -e ARM_TENANT_ID="xxx" \
  -v $(pwd):/workspace \
  -w /workspace \
  jenkins-terraform:latest bash
```

## Jenkins Configuration

### Jenkinsfile Example

```groovy
pipeline {
    agent {
        docker {
            image 'jenkins-terraform:latest'
            label 'docker'
        }
    }
    
    environment {
        ARM_CLIENT_ID       = credentials('azure-client-id')
        ARM_CLIENT_SECRET   = credentials('azure-client-secret')
        ARM_SUBSCRIPTION_ID = credentials('azure-subscription-id')
        ARM_TENANT_ID       = credentials('azure-tenant-id')
    }
    
    stages {
        stage('Authenticate') {
            steps {
                sh './scripts/azure-login.sh'
            }
        }
        
        stage('Deploy') {
            steps {
                sh './scripts/deploy.sh myapp tst --auto-approve'
            }
        }
    }
}
```

## Authentication

### Service Principal (CI/CD)

Required environment variables:
- `ARM_CLIENT_ID` - Service Principal App ID
- `ARM_CLIENT_SECRET` - Service Principal Secret
- `ARM_SUBSCRIPTION_ID` - Azure Subscription ID
- `ARM_TENANT_ID` - Azure AD Tenant ID

Set in Jenkins Credentials Manager and use `azure-login.sh` script.

### Local Testing

```bash
# Set credentials
export ARM_CLIENT_ID="xxx"
export ARM_CLIENT_SECRET="xxx"
export ARM_SUBSCRIPTION_ID="xxx"
export ARM_TENANT_ID="xxx"

# Navigate to project root (where scripts/ folder is)
cd /path/to/terraform-azure-project

# Start interactive container with volume mount
docker run -it --rm \
  -e ARM_CLIENT_ID \
  -e ARM_CLIENT_SECRET \
  -e ARM_SUBSCRIPTION_ID \
  -e ARM_TENANT_ID \
  -v $(pwd):/workspace \
  -w /workspace \
  jenkins-terraform:latest bash

# Inside container - authenticate (use bash explicitly)
bash scripts/poc/azure-login.sh

# Verify authentication
az account show

# Test Terraform workflow
cd terraform-project-template
bash ../scripts/poc/configure.sh myapp tst git@gitlab.com:yourgroup/terraform-project-template.git
bash ../scripts/poc/deploy.sh myapp tst
```

**Note**: Always use `bash scripts/poc/script.sh` instead of `./scripts/poc/script.sh` to avoid shebang and permission issues.

**Important**: Run `docker run` from the project root directory (`terraform-azure-project/`).

## Security

- Non-root user: `jenkins` (UID 1000)
- No credentials in image
- Minimal base (Alpine Linux)
- Multi-stage build
- Security scanning ready

## Troubleshooting

### Azure CLI not found

```bash
# Verify installation
docker run --rm jenkins-terraform:latest which az
docker run --rm jenkins-terraform:latest az version
```

### Authentication fails

Ensure environment variables are set and service principal has access to subscription.

## Maintenance

Update tool versions in Dockerfile:

```dockerfile
ARG TERRAFORM_VERSION=1.6.0
ARG TFSEC_VERSION=1.28.5
```

Then rebuild:
```bash
docker build -t jenkins-terraform:latest .
```

## Quick Start

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

## Jenkins Configuration

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
