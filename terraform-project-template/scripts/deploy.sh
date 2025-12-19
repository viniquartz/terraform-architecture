#!/bin/bash
#
# Script: deploy.sh
# Purpose: Complete Terraform deployment workflow (init → plan → apply)
#
# What it does:
# - Calls init-backend.sh to configure remote state
# - Generates Terraform execution plan
# - Applies changes to Azure infrastructure
# - Provides option for auto-approval (CI/CD usage)
#
# Usage: ./deploy.sh <project-name> <environment> [--auto-approve]
# Example: ./deploy.sh myapp tst
#          ./deploy.sh myapp prd --auto-approve
#

set -e

PROJECT_NAME=${1}
ENVIRONMENT=${2}
AUTO_APPROVE=${3}

if [ -z "$PROJECT_NAME" ] || [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <project-name> <environment> [--auto-approve]"
    echo "Example: $0 myapp prd"
    echo "         $0 myapp tst --auto-approve"
    exit 1
fi

echo "========================================"
echo "Terraform Deployment Workflow"
echo "========================================"
echo "Project: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "========================================"

# Step 1: Initialize backend
echo ""
echo "[STEP 1/3] Initializing backend..."
./scripts/init-backend.sh "$PROJECT_NAME" "$ENVIRONMENT"

# Step 2: Generate plan
echo ""
echo "[STEP 2/3] Generating execution plan..."
terraform plan \
    -var="environment=$ENVIRONMENT" \
    -var="project_name=$PROJECT_NAME" \
    -out=tfplan

# Step 3: Apply changes
echo ""
echo "[STEP 3/3] Applying changes..."
if [ "$AUTO_APPROVE" = "--auto-approve" ]; then
    echo "[INFO] Auto-approval enabled"
    terraform apply -auto-approve tfplan
else
    echo "[INFO] Manual approval required"
    terraform apply tfplan
fi

# Completion
if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "[SUCCESS] Deployment completed"
    echo "========================================"
    echo "Project: $PROJECT_NAME"
    echo "Environment: $ENVIRONMENT"
    echo ""
    echo "View outputs:"
    echo "  terraform output"
    echo ""
    echo "Destroy resources:"
    echo "  terraform destroy"
    echo "========================================"
else
    echo ""
    echo "[ERROR] Deployment failed"
    exit 1
fi
