#!/bin/bash
# Complete deploy: init + plan + apply

set -e

PROJECT_NAME=${1}
ENVIRONMENT=${2}
AUTO_APPROVE=${3}

if [ -z "$PROJECT_NAME" ] || [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <project-name> <environment> [--auto-approve]"
    echo "Example: $0 my-project prd"
    exit 1
fi

echo "[INFO] Deploying $PROJECT_NAME to $ENVIRONMENT"

# Initialize backend
./scripts/init-backend.sh "$PROJECT_NAME" "$ENVIRONMENT"

# Plan
echo "[INFO] Generating plan"
terraform plan \
    -var="environment=$ENVIRONMENT" \
    -var="project_name=$PROJECT_NAME" \
    -out=tfplan

# Apply
if [ "$AUTO_APPROVE" = "--auto-approve" ]; then
    echo "[INFO] Applying changes (auto-approve)"
    terraform apply -auto-approve tfplan
else
    echo "[INFO] Applying changes"
    terraform apply tfplan
fi

if [ $? -eq 0 ]; then
    echo "[OK] Deploy completed"
else
    echo "[ERROR] Deploy failed"
    exit 1
fi
