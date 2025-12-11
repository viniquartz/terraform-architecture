#!/bin/bash
# Script para criar Service Principals para Terraform

set -e

log_info() { echo "[INFO] $1"; }
log_error() { echo "[ERROR] $1"; exit 1; }
log_warning() { echo "[WARNING] $1"; }

# Verificações
if ! command -v az &> /dev/null; then
    log_error "Azure CLI nao instalado"
fi

if ! az account show &> /dev/null; then
    log_error "Execute: az login"
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

log_info "Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# Criar Service Principals por ambiente
ENVIRONMENTS=("prd" "qlt" "tst")

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
    log_info "Aguardando propagacao (10s)"
    sleep 10
    
    log_info "$SP_NAME configurado"
    echo ""
done

# Criar arquivo para Jenkins
log_info "Gerando arquivo de credenciais"

cat > ".credentials/jenkins-credentials.txt" <<'EOF'
CREDENCIAIS PARA JENKINS

Adicione no Jenkins Credentials Plugin:

Para cada ambiente (prd, qlt, tst):
  1. Username with password
     ID: azure-sp-{environment}
     Username: {client_id}
     Password: {client_secret}

  2. Secret text
     ID: azure-tenant-id
     Secret: {tenant_id}

  3. Secret text
     ID: azure-subscription-id
     Secret: {subscription_id}

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
log_info "Service Principals criados"
log_info "=========================================="
log_info ""
log_info "Arquivos em .credentials/:"
log_info "  - prd-sp.json"
log_info "  - qlt-sp.json"
log_info "  - tst-sp.json"
log_info "  - jenkins-credentials.txt"
log_info ""
log_info "IMPORTANTE:"
log_info "  1. Adicione credenciais no Jenkins"
log_info "  2. NAO comite .credentials/ no Git"
log_info "  3. Guarde em local seguro"
log_info ""
log_info "Para testar:"
log_info "  az login --service-principal -u <APP_ID> -p <PASSWORD> --tenant <TENANT_ID>"
log_info "=========================================="
