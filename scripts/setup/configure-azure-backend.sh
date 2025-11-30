#!/bin/bash
# Script para configurar o backend do Terraform no Azure Storage

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para logging
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Verificar se Azure CLI está instalado
if ! command -v az &> /dev/null; then
    log_error "Azure CLI não está instalado. Instale: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

# Verificar se está logado
if ! az account show &> /dev/null; then
    log_error "Você não está logado no Azure. Execute: az login"
    exit 1
fi

# Parâmetros
RESOURCE_GROUP_NAME="${1:-rg-terraform-state-prod-eastus}"
STORAGE_ACCOUNT_NAME="${2:-stterraformstate$(date +%s)}"
CONTAINER_NAME="${3:-tfstate}"
LOCATION="${4:-eastus}"

log_info "Configurando backend do Terraform..."
log_info "Resource Group: $RESOURCE_GROUP_NAME"
log_info "Storage Account: $STORAGE_ACCOUNT_NAME"
log_info "Container: $CONTAINER_NAME"
log_info "Location: $LOCATION"

# Criar Resource Group
log_info "Criando Resource Group..."
if az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
    log_warning "Resource Group já existe, pulando criação"
else
    az group create \
        --name "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --tags Environment=Production ManagedBy=Script Purpose=TerraformState
    log_info "Resource Group criado com sucesso"
fi

# Criar Storage Account
log_info "Criando Storage Account..."
if az storage account show --name "$STORAGE_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
    log_warning "Storage Account já existe, pulando criação"
else
    az storage account create \
        --name "$STORAGE_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --location "$LOCATION" \
        --sku Standard_GRS \
        --encryption-services blob \
        --https-only true \
        --min-tls-version TLS1_2 \
        --allow-blob-public-access false \
        --tags Environment=Production ManagedBy=Script Purpose=TerraformState
    log_info "Storage Account criado com sucesso"
fi

# Habilitar soft delete
log_info "Habilitando soft delete para blobs..."
az storage blob service-properties delete-policy update \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --enable true \
    --days-retained 30

# Habilitar versioning
log_info "Habilitando versioning para blobs..."
az storage account blob-service-properties update \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --enable-versioning true

# Obter Storage Account Key
ACCOUNT_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --query '[0].value' -o tsv)

# Criar Container
log_info "Criando container..."
if az storage container show \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --account-key "$ACCOUNT_KEY" &> /dev/null; then
    log_warning "Container já existe, pulando criação"
else
    az storage container create \
        --name "$CONTAINER_NAME" \
        --account-name "$STORAGE_ACCOUNT_NAME" \
        --account-key "$ACCOUNT_KEY" \
        --public-access off
    log_info "Container criado com sucesso"
fi

# Configurar RBAC (Contributor para Service Principal)
log_info "Aplicando RBAC..."
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SCOPE="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME"

# Buscar Service Principal (assumindo que já existe)
SP_NAME="${SP_NAME:-terraform-sp}"
SP_OBJECT_ID=$(az ad sp list --display-name "$SP_NAME" --query '[0].id' -o tsv)

if [ -n "$SP_OBJECT_ID" ]; then
    az role assignment create \
        --assignee "$SP_OBJECT_ID" \
        --role "Storage Blob Data Contributor" \
        --scope "$SCOPE" || log_warning "Role assignment pode já existir"
    log_info "RBAC configurado para Service Principal"
else
    log_warning "Service Principal '$SP_NAME' não encontrado, pulando RBAC"
fi

# Gerar configuração do backend
log_info "Gerando configuração do backend..."
cat > backend-config.hcl <<EOF
# Backend Configuration for Terraform
# Use this file with: terraform init -backend-config=backend-config.hcl

resource_group_name  = "$RESOURCE_GROUP_NAME"
storage_account_name = "$STORAGE_ACCOUNT_NAME"
container_name       = "$CONTAINER_NAME"
key                  = "terraform.tfstate"  # Altere conforme necessário
EOF

log_info "Configuração do backend salva em: backend-config.hcl"

# Exibir exemplo de uso no Terraform
cat > backend-example.tf <<EOF
# Exemplo de configuração de backend no Terraform
terraform {
  backend "azurerm" {
    resource_group_name  = "$RESOURCE_GROUP_NAME"
    storage_account_name = "$STORAGE_ACCOUNT_NAME"
    container_name       = "$CONTAINER_NAME"
    key                  = "project-name/environment/terraform.tfstate"
  }
}
EOF

log_info "Exemplo de backend.tf salvo em: backend-example.tf"

# Exibir credenciais do Jenkins
log_info ""
log_info "=========================================="
log_info "CREDENCIAIS PARA JENKINS"
log_info "=========================================="
log_info "Tipo: Secret text"
log_info "ID: terraform-backend-storage-account"
log_info "Valor: $STORAGE_ACCOUNT_NAME"
log_info ""
log_info "Tipo: Secret text"
log_info "ID: terraform-backend-resource-group"
log_info "Valor: $RESOURCE_GROUP_NAME"
log_info ""
log_info "Tipo: Secret text"
log_info "ID: terraform-backend-container"
log_info "Valor: $CONTAINER_NAME"
log_info "=========================================="

log_info ""
log_info "✅ Backend do Terraform configurado com sucesso!"
log_info ""
log_info "Próximos passos:"
log_info "1. Adicione as credenciais no Jenkins"
log_info "2. Use backend-example.tf como referência"
log_info "3. Execute: terraform init"
