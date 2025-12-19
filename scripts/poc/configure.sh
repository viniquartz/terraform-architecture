#!/bin/bash
# 
# Script: configure.sh
# Purpose: Configure Terraform backend and validate configuration
# 
# What it does:
# - Validates prerequisites (Azure CLI, Terraform)
# - Checks Azure authentication
# - Validates backend resources exist
# - Generates backend-config.tfbackend file
# - Initializes Terraform with remote state backend
# - Validates and formats Terraform configuration
#
# Usage: ./configure.sh <project-name> <environment> <workspace-path>
# Example: ./configure.sh myapp tst ../../terraform-project-template
#

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

PROJECT_NAME=${1}
ENVIRONMENT=${2}
WORKSPACE_PATH=${3:-"."}

if [ -z "$PROJECT_NAME" ] || [ -z "$ENVIRONMENT" ]; then
    log_error "Missing required parameters"
    echo "Usage: $0 <project-name> <environment> [workspace-path]"
    echo "Example: $0 myapp prd"
    echo "         $0 myapp tst ../../terraform-project-template"
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(prd|qlt|tst)$ ]]; then
    log_error "Invalid environment: $ENVIRONMENT"
    echo "Valid environments: prd, qlt, tst"
    exit 1
fi

# Validate Azure CLI is installed
if ! command -v az &> /dev/null; then
    log_error "Azure CLI is not installed"
    echo "Install: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

log_info "Azure CLI found: $(az version --query '\"azure-cli\"' -o tsv)"

# Validate Azure CLI authentication
log_info "Checking Azure authentication..."
if ! az account show &> /dev/null; then
    log_error "Not authenticated to Azure"
    echo ""
    echo "Authentication methods:"
    echo "  Local: az login"
    echo "  CI/CD: Use service principal with environment variables"
    echo "    ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID"
    echo ""
    echo "Or login with service principal:"
    echo "  az login --service-principal -u \$ARM_CLIENT_ID -p \$ARM_CLIENT_SECRET --tenant \$ARM_TENANT_ID"
    exit 1
fi

SUBSCRIPTION_NAME=$(az account show --query 'name' -o tsv)
SUBSCRIPTION_ID=$(az account show --query 'id' -o tsv)
log_info "Authenticated to subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# Validate Terraform is installed
if ! command -v terraform &> /dev/null; then
    log_error "Terraform is not installed"
    echo "Install: https://www.terraform.io/downloads"
    exit 1
fi

TERRAFORM_VERSION=$(terraform version -json | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4)
log_info "Terraform found: v$TERRAFORM_VERSION"

# Backend configuration
# Note: Update these values with output from configure-azure-backend.sh
RESOURCE_GROUP="rg-terraform-backend"
STORAGE_ACCOUNT="sttfbackend<unique>"  # Replace <unique> with actual value
CONTAINER_NAME="terraform-state-${ENVIRONMENT}"
STATE_KEY="${PROJECT_NAME}.tfstate"

log_info "Validating backend resources..."

# Check if resource group exists
if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    log_error "Resource group '$RESOURCE_GROUP' not found"
    echo "Create backend: cd scripts/setup && ./configure-azure-backend.sh"
    exit 1
fi
log_info "Resource group found: $RESOURCE_GROUP"

# Check if storage account exists
if ! az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    log_error "Storage account '$STORAGE_ACCOUNT' not found"
    echo "Create backend: cd scripts/setup && ./configure-azure-backend.sh"
    exit 1
fi
log_info "Storage account found: $STORAGE_ACCOUNT"

# Check if container exists (create if not)
if ! az storage container show --name "$CONTAINER_NAME" --account-name "$STORAGE_ACCOUNT" --auth-mode login &> /dev/null; then
    log_warn "Container '$CONTAINER_NAME' not found, creating..."
    az storage container create \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT" \
        --auth-mode login \
        --output none
    log_info "Container created: $CONTAINER_NAME"
else
    log_info "Container found: $CONTAINER_NAME"
fi

echo ""
log_info "Initializing Terraform backend"
echo "  Project: $PROJECT_NAME"
echo "  Environment: $ENVIRONMENT"
echo "  Container: $CONTAINER_NAME"
echo "  State Key: $STATE_KEY"

# Create backend configuration file
cat > backend-config.tfbackend <<EOF
resource_group_name  = "$RESOURCE_GROUP"
storage_account_name = "$STORAGE_ACCOUNT"
container_name       = "$CONTAINER_NAME"
key                  = "$STATE_KEY"
EOF

log_info "Generated backend-config.tfbackend"

# Validate Terraform configuration
log_info "Validating Terraform configuration..."

# Change to workspace directory
cd "$WORKSPACE_PATH" || {
    log_error "Workspace path not found: $WORKSPACE_PATH"
    exit 1
}

if ! terraform fmt -check &> /dev/null; then
    log_warn "Terraform files are not formatted, formatting now..."
    terraform fmt -recursive
    log_info "Files formatted successfully"
fi

if ! terraform validate &> /dev/null; then
    log_error "Terraform configuration is invalid"
    terraform validate
    exit 1
fi
log_info "Terraform configuration is valid"

# Initialize Terraform with backend
echo ""
log_info "Running terraform init..."
terraform init -backend-config=backend-config.tfbackend -reconfigure

if [ $? -eq 0 ]; then
    echo ""
    log_info "Configuration completed successfully"
    log_info "State location: $STORAGE_ACCOUNT/$CONTAINER_NAME/$STATE_KEY"
    log_info "Workspace: $WORKSPACE_PATH"
else
    log_error "Failed to initialize backend"
    exit 1
fi
