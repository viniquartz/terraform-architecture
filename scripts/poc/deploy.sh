#!/bin/bash
#
# Script: deploy.sh
# Purpose: Generate Terraform plan and apply changes
#
# What it does:
# - Changes to project workspace directory
# - Generates Terraform execution plan to file
# - Reviews plan output
# - Applies plan after user confirmation
#
# Usage: ./deploy.sh <project-name> <environment>
# Example: ./deploy.sh myapp tst
#          ./deploy.sh myapp prd
#
# Prerequisites: 
# - Run configure.sh first
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
    echo "Run configure.sh first:"
    echo "  bash scripts/poc/configure.sh $PROJECT_NAME $ENVIRONMENT <gitlab-repo-url>"
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

PLAN_FILE="tfplan-${ENVIRONMENT}.out"

echo "========================================"
echo "Terraform Deploy Workflow"
echo "========================================"
echo "Project:     $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Workspace:   $(pwd)"
echo "Variables:   $TFVARS_FILE"
echo "Plan output: $PLAN_FILE"
echo "========================================"

# Step 1: Generate plan
echo ""
log_step "[STEP 1/3] Generating execution plan..."
log_info "Running terraform plan..."

if terraform plan \
    -var-file="$TFVARS_FILE" \
    -out="$PLAN_FILE"; then
    log_info "✓ Plan generated successfully"
else
    log_error "Failed to generate plan"
    exit 1
fi

# Step 2: Show plan summary
echo ""
log_step "[STEP 2/3] Plan Summary"
echo ""
terraform show -no-color "$PLAN_FILE" | grep -E "Plan:|No changes" || true
echo ""

# Step 3: Confirm and apply
echo ""
log_step "[STEP 3/3] Apply changes"
log_warn "Review the plan above carefully"
echo ""
read -p "Do you want to apply these changes? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    log_warn "Deployment cancelled by user"
    log_info "Plan file saved: $PLAN_FILE"
    log_info "To apply later: terraform apply $PLAN_FILE"
    exit 0
fi

log_info "Applying plan..."
if terraform apply "$PLAN_FILE"; then
    log_info "✓ Changes applied successfully"
    
    # Clean up plan file after successful apply
    rm -f "$PLAN_FILE"
    log_info "Plan file removed: $PLAN_FILE"
else
    log_error "Failed to apply changes"
    log_info "Plan file preserved: $PLAN_FILE"
    exit 1
fi

# Completion
echo ""
echo "========================================"
log_info "Deployment completed successfully!"
echo "========================================"
echo "Project:     $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo ""
echo "Useful commands:"
echo "  terraform output                              - View all outputs"
echo "  terraform show                                - Show current state"
echo "  terraform state list                          - List resources"
echo "  bash ../scripts/poc/destroy.sh $PROJECT_NAME $ENVIRONMENT - Destroy resources"
echo "========================================"
