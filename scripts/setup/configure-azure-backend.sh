#!/bin/bash
# Script to configure Terraform backend on Azure Storage

set -e

log_info() { echo "[INFO] $1"; }
log_error() { echo "[ERROR] $1"; exit 1; }
log_warning() { echo "[WARNING] $1"; }

# Check Azure CLI
if ! command -v az &> /dev/null; then
    log_error "Azure CLI not installed"
fi

if ! az account show &> /dev/null; then
    log_error "Run: az login"
fi

# Parameters
RESOURCE_GROUP_NAME="${1:-rg-terraform-state}"
STORAGE_ACCOUNT_NAME="${2:-stterraformstate}"
LOCATION="${3:-brazilsouth}"

# Containers to create
CONTAINERS=("terraform-state-prd" "terraform-state-qlt" "terraform-state-tst")

log_info "Configuring Terraform backend"
log_info "Resource Group: $RESOURCE_GROUP_NAME"
log_info "Storage Account: $STORAGE_ACCOUNT_NAME"
log_info "Location: $LOCATION"

# Create Resource Group
log_info "Creating Resource Group"
if az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
    log_warning "Resource Group already exists"
else
    az group create \
        --name "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --tags ManagedBy=Terraform
    log_info "Resource Group created"
fi

# Create Storage Account
log_info "Creating Storage Account"
if az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
    log_warning "Storage Account already exists"
else
    az storage account create \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --sku Standard_GRS \
        --encryption-services blob \
        --https-only true \
        --min-tls-version TLS1_2 \
        --allow-blob-public-access false
    log_info "Storage Account created"
fi

# Enable soft delete
log_info "Enabling soft delete"
az storage blob service-properties delete-policy update \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --enable true \
    --days-retained 30 &> /dev/null || log_warning "Soft delete may already be enabled"

# Enable versioning
log_info "Enabling versioning"
az storage account blob-service-properties update \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --enable-versioning true &> /dev/null || log_warning "Versioning may already be enabled"

# Get Storage Account Key
ACCOUNT_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --query '[0].value' -o tsv)

# Create Containers
log_info "Creating containers"
for CONTAINER_NAME in "${CONTAINERS[@]}"; do
    if az storage container show \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --account-key "$ACCOUNT_KEY" &> /dev/null; then
        log_warning "Container $CONTAINER_NAME already exists"
    else
        az storage container create \
            --name "$CONTAINER_NAME" \
            --account-name "$STORAGE_ACCOUNT_NAME" \
            --account-key "$ACCOUNT_KEY" \
            --public-access off
        log_info "Container $CONTAINER_NAME created"
    fi
done

log_info ""
log_info "=========================================="
log_info "Backend configured successfully"
log_info "=========================================="
log_info "Resource Group: $RESOURCE_GROUP_NAME"
log_info "Storage Account: $STORAGE_ACCOUNT_NAME"
log_info ""
log_info "Containers created:"
for CONTAINER_NAME in "${CONTAINERS[@]}"; do
    log_info "  - $CONTAINER_NAME"
done
log_info ""
log_info "Use these values in backend.tf:"
log_info "  resource_group_name  = \"$RESOURCE_GROUP_NAME\""
log_info "  storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
log_info "  container_name       = \"terraform-state-{environment}\""
log_info "  key                  = \"{project-name}/terraform.tfstate\""
log_info "=========================================="
