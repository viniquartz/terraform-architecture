#!/bin/bash
#
# Script: destroy.sh
# Purpose: Destroy infrastructure provisioned by Terraform
#
# What it does:
# - Changes to project workspace directory
# - Generates Terraform destroy plan to file
# - Reviews resources to be destroyed
# - Destroys infrastructure after confirmation
#
# Usage: ./destroy.sh <project-name> <environment>
# Example: ./destroy.sh myapp tst
#          ./destroy.sh myapp prd
#
# Prerequisites: Infrastructure must be deployed
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

if [ -z "$PROJECT_NAME" ] || [ -z "$ENVIRONMENT" ]; then
    log_error "Missing required parameters"
    echo "Usage: $0 <project-name> <environment>"
    echo ""
    echo "Examples:"
    echo "  $0 myapp tst"
    echo "  $0 myapp qlt"
    echo "  $0 myapp prd"
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(prd|qlt|tst)$ ]]; then
    log_error "Invalid environment: $ENVIRONMENT"
    echo "Valid environments: prd, qlt, tst"
    exit 1
fi

WORKSPACE_DIR="$PROJECT_NAME"

# Check if workspace directory exists
if [ ! -d "$WORKSPACE_DIR" ]; then
    log_error "Workspace directory not found: $WORKSPACE_DIR"
    echo ""
    echo "Project may not be configured or already destroyed."
    exit 1
fi

# Change to workspace directory
cd "$WORKSPACE_DIR" || {
    log_error "Failed to change to workspace directory: $WORKSPACE_DIR"
    exit 1
}

# Check if main.tf exists
if [ ! -f "main.tf" ]; then
    log_error "main.tf not found in workspace directory"
    exit 1
fi

# Check if tfvars exists
TFVARS_FILE="environments/${ENVIRONMENT}/terraform.tfvars"
if [ ! -f "$TFVARS_FILE" ]; then
    log_error "Terraform variables file not found: $TFVARS_FILE"
    exit 1
fi

DESTROY_PLAN_FILE="tfplan-destroy-${ENVIRONMENT}.out"

echo "========================================"
echo "Terraform Destroy Workflow"
echo "========================================"
echo "Project:     $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Workspace:   $(pwd)"
echo "Variables:   $TFVARS_FILE"
echo "Plan output: $DESTROY_PLAN_FILE"
echo "========================================"
echo ""
log_warn "⚠️  WARNING: This will DESTROY all infrastructure!"
echo ""

# Step 1: Show current state
echo ""
log_step "[STEP 1/4] Current infrastructure state"
log_info "Resources currently managed:"
terraform state list || log_warn "No state file found"

# Step 2: Generate destroy plan
echo ""
log_step "[STEP 2/4] Generating destroy plan..."
log_info "Running terraform plan -destroy..."

if terraform plan -destroy \
    -var-file="$TFVARS_FILE" \
    -out="$DESTROY_PLAN_FILE"; then
    log_info "✓ Destroy plan generated successfully"
else
    log_error "Failed to generate destroy plan"
    exit 1
fi

# Step 3: Show plan summary
echo ""
log_step "[STEP 3/4] Destroy Plan Summary"
echo ""
terraform show -no-color "$DESTROY_PLAN_FILE" | grep -E "Plan:|No changes" || true
echo ""

# Step 4: Confirm and destroy
echo ""
log_step "[STEP 4/4] Destroy infrastructure"
log_warn "⚠️  DANGER: This will permanently delete all resources!"
log_warn "Review the destroy plan above carefully"
echo ""
read -p "Type 'yes' to confirm destruction: " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    log_warn "Destruction cancelled by user"
    log_info "Destroy plan file saved: $DESTROY_PLAN_FILE"
    log_info "To destroy later: terraform apply $DESTROY_PLAN_FILE"
    exit 0
fi

log_info "Applying destroy plan..."
if terraform apply "$DESTROY_PLAN_FILE"; then
    log_info "✓ Infrastructure destroyed successfully"
    
    # Clean up plan file after successful destroy
    rm -f "$DESTROY_PLAN_FILE"
    log_info "Destroy plan file removed: $DESTROY_PLAN_FILE"
else
    log_error "Failed to destroy infrastructure"
    log_info "Destroy plan file preserved: $DESTROY_PLAN_FILE"
    exit 1
fi

# Completion
echo ""
echo "========================================"
log_info "Infrastructure destroyed successfully!"
echo "========================================"
echo "Project:     $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo ""
log_info "State file remains in Azure Storage for audit purposes."
echo ""
echo "To clean up workspace directory:"
echo "  cd .."
echo "  rm -rf $WORKSPACE_DIR"
echo "========================================"
