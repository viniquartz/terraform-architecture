#!/bin/bash
#
# Script: deploy.sh
# Purpose: Generate Terraform plan and apply changes
#
# What it does:
# - Changes to workspace directory
# - Generates Terraform execution plan
# - Applies changes to Azure infrastructure
# - Provides option for auto-approval (CI/CD usage)
#
# Usage: ./deploy.sh <project-name> <environment> <workspace-path> [--auto-approve]
# Example: ./deploy.sh myapp tst ../../terraform-project-template
#          ./deploy.sh myapp prd ../../terraform-project-template --auto-approve
#
# Prerequisites: Run configure.sh first
#

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

PROJECT_NAME=${1}
ENVIRONMENT=${2}
WORKSPACE_PATH=${3:-"."}
AUTO_APPROVE=${4}

if [ -z "$PROJECT_NAME" ] || [ -z "$ENVIRONMENT" ]; then
    log_error "Missing required parameters"
    echo "Usage: $0 <project-name> <environment> [workspace-path] [--auto-approve]"
    echo "Example: $0 myapp prd"
    echo "         $0 myapp tst ../../terraform-project-template --auto-approve"
    exit 1
fi

echo "========================================"
echo "Terraform Deploy Workflow"
echo "========================================"
echo "Project: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Workspace: $WORKSPACE_PATH"
echo "Auto-approve: ${AUTO_APPROVE:-false}"
echo "========================================"

# Change to workspace directory
cd "$WORKSPACE_PATH" || {
    log_error "Workspace path not found: $WORKSPACE_PATH"
    exit 1
}

# Step 1: Generate plan
echo ""
log_step "[STEP 1/2] Generating execution plan..."
terraform plan \
    -var="environment=$ENVIRONMENT" \
    -var="project_name=$PROJECT_NAME" \
    -out=tfplan

# Step 2: Apply changes
echo ""
log_step "[STEP 2/2] Applying changes..."
if [ "$AUTO_APPROVE" = "--auto-approve" ]; then
    log_info "Auto-approval enabled (CI/CD mode)"
    terraform apply -auto-approve tfplan
else
    log_info "Manual approval required"
    terraform apply tfplan
fi

# Completion
if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    log_info "Deployment completed successfully"
    echo "========================================"
    echo "Project: $PROJECT_NAME"
    echo "Environment: $ENVIRONMENT"
    echo ""
    echo "Useful commands:"
    echo "  terraform output          - View all outputs"
    echo "  terraform show            - Show current state"
    echo "  terraform state list      - List resources"
    echo "  ./destroy.sh $PROJECT_NAME $ENVIRONMENT $WORKSPACE_PATH - Destroy resources"
    echo "========================================"
else
    echo ""
    log_error "Deployment failed"
    echo "Check errors above and retry"
    exit 1
fi
