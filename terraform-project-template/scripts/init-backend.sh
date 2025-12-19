#!/bin/bash
# 
# Script: init-backend.sh
# Purpose: Initialize Terraform backend with dynamic configuration
# 
# What it does:
# - Validates project name and environment
# - Generates backend-config.tfbackend file
# - Initializes Terraform with remote state backend
# - Reconfigures backend if already initialized
#
# Usage: ./init-backend.sh <project-name> <environment>
# Example: ./init-backend.sh myapp tst
#

set -e

PROJECT_NAME=${1}
ENVIRONMENT=${2}

if [ -z "$PROJECT_NAME" ] || [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <project-name> <environment>"
    echo "Example: $0 myapp prd"
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(prd|qlt|tst)$ ]]; then
    echo "Invalid environment: $ENVIRONMENT"
    echo "Use: prd, qlt or tst"
    exit 1
fi

# Backend configuration
# Note: Update these values with output from configure-azure-backend.sh
RESOURCE_GROUP="rg-terraform-backend"
STORAGE_ACCOUNT="sttfbackend<unique>"  # Replace <unique> with actual value
CONTAINER_NAME="terraform-state-${ENVIRONMENT}"
STATE_KEY="${PROJECT_NAME}.tfstate"

echo "[INFO] Initializing Terraform backend"
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

echo "[INFO] Generated backend-config.tfbackend"

# Initialize Terraform with backend
terraform init -backend-config=backend-config.tfbackend -reconfigure

if [ $? -eq 0 ]; then
    echo "[OK] Backend initialized successfully"
else
    echo "[ERROR] Failed to initialize backend"
    exit 1
fi
