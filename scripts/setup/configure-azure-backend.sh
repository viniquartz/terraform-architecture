#!/bin/bash
# Script para configurar o backend do Terraform no Azure Storage

set -e

log_info() { echo "[INFO] $1"; }
log_error() { echo "[ERROR] $1"; exit 1; }
log_warning() { echo "[WARNING] $1"; }

# Verificar Azure CLI
if ! command -v az &> /dev/null; then
    log_error "Azure CLI nao instalado"
fi

if ! az account show &> /dev/null; then
    log_error "Execute: az login"
fi

# Parametros
RESOURCE_GROUP_NAME="${1:-rg-terraform-state}"
STORAGE_ACCOUNT_NAME="${2:-stterraformstate}"
LOCATION="${3:-brazilsouth}"

# Containers a serem criados
CONTAINERS=("terraform-state-prd" "terraform-state-qlt" "terraform-state-tst")

log_info "Configurando backend do Terraform"
log_info "Resource Group: $RESOURCE_GROUP_NAME"
log_info "Storage Account: $STORAGE_ACCOUNT_NAME"
log_info "Location: $LOCATION"

# Criar Resource Group
log_info "Criando Resource Group"
if az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
    log_warning "Resource Group ja existe"
else
    az group create \
        --name "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --tags ManagedBy=Terraform
    log_info "Resource Group criado"
fi

# Criar Storage Account
log_info "Criando Storage Account"
if az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
    log_warning "Storage Account ja existe"
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
    log_info "Storage Account criado"
fi

# Habilitar soft delete
log_info "Habilitando soft delete"
az storage blob service-properties delete-policy update \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --enable true \
    --days-retained 30 &> /dev/null || log_warning "Soft delete pode ja estar habilitado"

# Habilitar versioning
log_info "Habilitando versioning"
az storage account blob-service-properties update \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --enable-versioning true &> /dev/null || log_warning "Versioning pode ja estar habilitado"

# Obter Storage Account Key
ACCOUNT_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --query '[0].value' -o tsv)

# Criar Containers
log_info "Criando containers"
for CONTAINER_NAME in "${CONTAINERS[@]}"; do
    if az storage container show \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --account-key "$ACCOUNT_KEY" &> /dev/null; then
        log_warning "Container $CONTAINER_NAME ja existe"
    else
        az storage container create \
            --name "$CONTAINER_NAME" \
            --account-name "$STORAGE_ACCOUNT_NAME" \
            --account-key "$ACCOUNT_KEY" \
            --public-access off
        log_info "Container $CONTAINER_NAME criado"
    fi
done

log_info ""
log_info "=========================================="
log_info "Backend configurado com sucesso"
log_info "=========================================="
log_info "Resource Group: $RESOURCE_GROUP_NAME"
log_info "Storage Account: $STORAGE_ACCOUNT_NAME"
log_info ""
log_info "Containers criados:"
for CONTAINER_NAME in "${CONTAINERS[@]}"; do
    log_info "  - $CONTAINER_NAME"
done
log_info ""
log_info "Use estes valores no backend.tf:"
log_info "  resource_group_name  = \"$RESOURCE_GROUP_NAME\""
log_info "  storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
log_info "  container_name       = \"terraform-state-{environment}\""
log_info "  key                  = \"{project-name}/terraform.tfstate\""
log_info "=========================================="
