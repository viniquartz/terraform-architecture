#!/bin/bash
# Initialize Terraform backend dynamically

set -e

PROJECT_NAME=${1}
ENVIRONMENT=${2}

if [ -z "$PROJECT_NAME" ] || [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <project-name> <environment>"
    echo "Example: $0 my-project prd"
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(prd|qlt|tst)$ ]]; then
    echo "Invalid environment: $ENVIRONMENT"
    echo "Use: prd, qlt or tst"
    exit 1
fi

# Backend configuration
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="stterraformstate"
CONTAINER_NAME="terraform-state-${ENVIRONMENT}"
STATE_KEY="${PROJECT_NAME}/terraform.tfstate"

echo "[INFO] Initializing backend"
echo "  Project: $PROJECT_NAME"
echo "  Environment: $ENVIRONMENT"
echo "  Container: $CONTAINER_NAME"
echo "  Key: $STATE_KEY"

# Create configuration file
cat > backend-config.tfbackend <<EOF
resource_group_name  = "$RESOURCE_GROUP"
storage_account_name = "$STORAGE_ACCOUNT"
container_name       = "$CONTAINER_NAME"
key                  = "$STATE_KEY"
EOF

echo "[INFO] File backend-config.tfbackend created"

# Initialize Terraform
terraform init -backend-config=backend-config.tfbackend -reconfigure

if [ $? -eq 0 ]; then
    echo "[OK] Backend initialized"
else
    echo "[ERROR] Failed to initialize backend"
    exit 1
fi
