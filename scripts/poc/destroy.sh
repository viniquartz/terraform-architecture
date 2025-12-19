#!/bin/bash
#
# Script: destroy.sh
# Purpose: Destroy Terraform resources and clean up
#
# What it does:
# - Changes to workspace directory
# - Generates destruction plan
# - Destroys all managed resources
# - Provides option for auto-approval (CI/CD usage)
# - Optionally deletes state file from backend
#
# Usage: ./destroy.sh <project-name> <environment> <workspace-path> [--auto-approve] [--delete-state]
# Example: ./destroy.sh myapp tst ../../terraform-project-template
#          ./destroy.sh myapp tst ../../terraform-project-template --auto-approve --delete-state
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
AUTO_APPROVE=""
DELETE_STATE=false

# Parse optional arguments
for arg in "$@"; do
    if [ "$arg" = "--auto-approve" ]; then
        AUTO_APPROVE="--auto-approve"
    fi
    if [ "$arg" = "--delete-state" ]; then
        DELETE_STATE=true
    fi
done

if [ -z "$PROJECT_NAME" ] || [ -z "$ENVIRONMENT" ]; then
    log_error "Missing required parameters"
    echo "Usage: $0 <project-name> <environment> [workspace-path] [--auto-approve] [--delete-state]"
    echo "Example: $0 myapp tst"
    echo "         $0 myapp tst ../../terraform-project-template --auto-approve"
    echo "         $0 myapp tst ../../terraform-project-template --auto-approve --delete-state"
    echo ""
    echo "Options:"
    echo "  --auto-approve  : Skip confirmation prompt (CI/CD mode)"
    echo "  --delete-state  : Delete state file from backend after destroy"
    exit 1
fi

echo "========================================"
echo "Terraform Destroy Workflow"
echo "========================================"
echo "Project: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Workspace: $WORKSPACE_PATH"
echo "Auto-approve: ${AUTO_APPROVE:-false}"
echo "Delete state: $DELETE_STATE"
echo "========================================"
echo ""
log_warn "THIS WILL DESTROY ALL RESOURCES!"
echo ""

# Prompt for confirmation if not auto-approved
if [ -z "$AUTO_APPROVE" ]; then
    read -p "Are you sure you want to destroy all resources? (type 'yes' to confirm): " confirmation
    if [ "$confirmation" != "yes" ]; then
        log_info "Destroy cancelled by user"
        exit 0
    fi
fi

# Change to workspace directory
cd "$WORKSPACE_PATH" || {
    log_error "Workspace path not found: $WORKSPACE_PATH"
    exit 1
}

# Step 1: Generate destroy plan
echo ""
log_step "[STEP 1/2] Generating destroy plan..."
terraform plan -destroy \
    -var="environment=$ENVIRONMENT" \
    -var="project_name=$PROJECT_NAME" \
    -out=tfplan-destroy

log_info "Destroy plan generated"
echo ""
log_warn "Resources to be destroyed:"
terraform show -json tfplan-destroy | grep -o '"change":{"actions":\["delete"\]}' | wc -l | xargs echo "  Total resources:"

# Step 2: Destroy resources
echo ""
log_step "[STEP 2/2] Destroying resources..."

if [ -n "$AUTO_APPROVE" ]; then
    log_info "Auto-approval enabled (CI/CD mode)"
    terraform apply -auto-approve tfplan-destroy
else
    log_info "Manual approval required"
    terraform apply tfplan-destroy
fi

# Completion
if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    log_info "Resources destroyed successfully"
    echo "========================================"
    
    # Delete state file if requested
    if [ "$DELETE_STATE" = true ]; then
        echo ""
        log_step "Deleting state file from backend..."
        
        # Read backend config
        if [ ! -f "backend-config.tfbackend" ]; then
            log_error "backend-config.tfbackend not found"
            exit 1
        fi
        
        source <(grep = backend-config.tfbackend | sed 's/ *= */=/g' | sed 's/"//g')
        
        log_info "Deleting state: $storage_account_name/$container_name/$key"
        
        if az storage blob delete \
            --account-name "$storage_account_name" \
            --container-name "$container_name" \
            --name "$key" \
            --auth-mode login \
            --output none 2>/dev/null; then
            log_info "State file deleted successfully"
        else
            log_warn "State file not found or already deleted"
        fi
    fi
    
    # Clean up local files
    echo ""
    log_info "Cleaning up local files..."
    rm -f tfplan-destroy
    rm -f backend-config.tfbackend
    rm -rf .terraform
    rm -f .terraform.lock.hcl
    log_info "Local files cleaned"
    
    echo ""
    echo "========================================"
    log_info "Cleanup completed"
    echo "========================================"
    echo "Project: $PROJECT_NAME"
    echo "Environment: $ENVIRONMENT"
    echo ""
    if [ "$DELETE_STATE" = true ]; then
        echo "State file deleted from backend"
    else
        echo "State file preserved in backend"
        echo "To delete state: ./destroy.sh $PROJECT_NAME $ENVIRONMENT $WORKSPACE_PATH --delete-state"
    fi
    echo "========================================"
else
    echo ""
    log_error "Destroy failed"
    echo "Check errors above and retry"
    exit 1
fi
