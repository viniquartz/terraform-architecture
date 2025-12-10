#!/bin/bash
# Script para criar Service Principals para uso do Terraform

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Verificações
if ! command -v az &> /dev/null; then
    log_error "Azure CLI nao instalado"
    exit 1
fi

if ! az account show &> /dev/null; then
    log_error "Execute: az login"
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

log_info "Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# Criar Service Principals por ambiente
ENVIRONMENTS=("prd" "qa" "tst")

for ENV in "${ENVIRONMENTS[@]}"; do
    SP_NAME="sp-terraform-${ENV}"
    
    log_info "Criando Service Principal: $SP_NAME"
    
    # Verificar se ja existe
    if az ad sp list --display-name "$SP_NAME" --query '[0].appId' -o tsv &> /dev/null; then
        APP_ID=$(az ad sp list --display-name "$SP_NAME" --query '[0].appId' -o tsv)
        log_warning "Service Principal ja existe (AppId: $APP_ID)"
        
        # Resetar credenciais
        log_info "Resetando credenciais..."
        CREDENTIALS=$(az ad sp credential reset --id "$APP_ID" --query "{appId: appId, password: password, tenant: tenant}" -o json)
    else
        # Criar novo
        CREDENTIALS=$(az ad sp create-for-rbac \
            --name "$SP_NAME" \
            --role Contributor \
            --scopes "/subscriptions/$SUBSCRIPTION_ID" \
            --query "{appId: appId, password: password, tenant: tenant}" \
            -o json)
        
        log_info "Service Principal criado"
    fi
    
    # Extrair valores
    APP_ID=$(echo "$CREDENTIALS" | jq -r '.appId')
    PASSWORD=$(echo "$CREDENTIALS" | jq -r '.password')
    TENANT_ID=$(echo "$CREDENTIALS" | jq -r '.tenant')
    
    # Salvar em arquivo seguro
    mkdir -p .credentials
    cat > ".credentials/${ENV}-sp.json" <<EOF
{
  "environment": "${ENV}",
  "client_id": "${APP_ID}",
  "client_secret": "${PASSWORD}",
  "tenant_id": "${TENANT_ID}",
  "subscription_id": "${SUBSCRIPTION_ID}"
}
EOF
    chmod 600 ".credentials/${ENV}-sp.json"
    
    log_info "Credenciais salvas em: .credentials/${ENV}-sp.json"
    
    # Aguardar propagação
    log_info "Aguardando propagação (30s)..."
    sleep 30
    
    # Adicionar roles adicionais para production
    if [ "$ENV" = "production" ]; then
        log_info "Adicionando roles adicionais para production..."
        
        az role assignment create \
            --assignee "$APP_ID" \
            --role "Key Vault Administrator" \
            --scope "/subscriptions/$SUBSCRIPTION_ID" || log_warning "Role pode ja existir"
        
        az role assignment create \
            --assignee "$APP_ID" \
            --role "Storage Account Contributor" \
            --scope "/subscriptions/$SUBSCRIPTION_ID" || log_warning "Role pode ja existir"
    fi
    
    log_info "[OK] $SP_NAME configurado\n"
done

# Criar arquivo para Jenkins credentials
log_info "Gerando script para Jenkins..."

cat > ".credentials/jenkins-credentials.txt" <<'EOF'
# CREDENCIAIS PARA JENKINS
# Adicione estas credenciais usando o Jenkins Credentials Plugin

Para cada ambiente (prd, qa, tst):

1. Tipo: Username with password
   ID: azure-sp-{environment}
   Username: {client_id}
   Password: {client_secret}
   Description: Azure Service Principal for {environment}

2. Tipo: Secret text
   ID: azure-tenant-id
   Secret: {tenant_id}
   Description: Azure Tenant ID

3. Tipo: Secret text
   ID: azure-subscription-id
   Secret: {subscription_id}
   Description: Azure Subscription ID

Valores:
EOF

for ENV in "${ENVIRONMENTS[@]}"; do
    cat >> ".credentials/jenkins-credentials.txt" <<EOF

--- ${ENV} ---
$(cat ".credentials/${ENV}-sp.json" | jq -r '"ID: azure-sp-" + .environment + "\nUsername: " + .client_id + "\nPassword: " + .client_secret + "\nTenant: " + .tenant_id + "\nSubscription: " + .subscription_id')

EOF
done

log_info ""
log_info "=========================================="
log_info "[OK] TODOS OS SERVICE PRINCIPALS CRIADOS"
log_info "=========================================="
log_info ""
log_info "Arquivos gerados em .credentials/:"
log_info "  - prd-sp.json"
log_info "  - qa-sp.json"
log_info "  - tst-sp.json"
log_info "  - jenkins-credentials.txt"
log_info ""
log_info "[IMPORTANTE]:"
log_info "1. Adicione as credenciais no Jenkins (ver jenkins-credentials.txt)"
log_info "2. NAO comite os arquivos .credentials/ no Git"
log_info "3. Guarde as credenciais em local seguro (ex: Azure Key Vault)"
log_info "4. Adicione .credentials/ no .gitignore"
log_info ""
log_info "Para testar o Service Principal:"
log_info "  az login --service-principal -u <APP_ID> -p <PASSWORD> --tenant <TENANT_ID>"
log_info ""
