#!/bin/bash
# Script to create Service Principals for Terraform

set -e

log_info() { echo "[INFO] $1"; }
log_error() { echo "[ERROR] $1"; exit 1; }
log_warning() { echo "[WARNING] $1"; }

# Checks
if ! command -v az &> /dev/null; then
    log_error "Azure CLI not installed"
fi

if ! az account show &> /dev/null; then
    log_error "Run: az login"
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

log_info "Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# Create Service Principals per environment
ENVIRONMENTS=("prd" "qlt" "tst")

for ENV in "${ENVIRONMENTS[@]}"; do
    SP_NAME="sp-terraform-${ENV}"
    
    log_info "Creating Service Principal: $SP_NAME"
    
    # Check if already exists
    if az ad sp list --display-name "$SP_NAME" --query '[0].appId' -o tsv &> /dev/null; then
        APP_ID=$(az ad sp list --display-name "$SP_NAME" --query '[0].appId' -o tsv)
        log_warning "Service Principal already exists (AppId: $APP_ID)"
        
        # Reset credentials
        log_info "Resetting credentials..."
        CREDENTIALS=$(az ad sp credential reset --id "$APP_ID" --query "{appId: appId, password: password, tenant: tenant}" -o json)
    else
        # Create new
        CREDENTIALS=$(az ad sp create-for-rbac \
            --name "$SP_NAME" \
            --role Contributor \
            --scopes "/subscriptions/$SUBSCRIPTION_ID" \
            --query "{appId: appId, password: password, tenant: tenant}" \
            -o json)
        
        log_info "Service Principal created"
    fi
    
    # Extract values
    APP_ID=$(echo "$CREDENTIALS" | jq -r '.appId')
    PASSWORD=$(echo "$CREDENTIALS" | jq -r '.password')
    TENANT_ID=$(echo "$CREDENTIALS" | jq -r '.tenant')
    
    # Save to secure file
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
    
    log_info "Credentials saved to: .credentials/${ENV}-sp.json"
    
    # Wait for propagation
    log_info "Waiting for propagation (10s)"
    sleep 10
    
    log_info "$SP_NAME configured"
    echo ""
done

# Create file for Jenkins
log_info "Generating credentials file"

cat > ".credentials/jenkins-credentials.txt" <<'EOF'
CREDENTIALS FOR JENKINS

Add to Jenkins Credentials Plugin:

For each environment (prd, qlt, tst):
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

Values:
EOF

for ENV in "${ENVIRONMENTS[@]}"; do
    cat >> ".credentials/jenkins-credentials.txt" <<EOF

--- ${ENV} ---
$(cat ".credentials/${ENV}-sp.json" | jq -r '"ID: azure-sp-" + .environment + "\nUsername: " + .client_id + "\nPassword: " + .client_secret + "\nTenant: " + .tenant_id + "\nSubscription: " + .subscription_id')

EOF
done

log_info ""
log_info "=========================================="
log_info "Service Principals created"
log_info "=========================================="
log_info ""
log_info "Files in .credentials/:"
log_info "  - prd-sp.json"
log_info "  - qlt-sp.json"
log_info "  - tst-sp.json"
log_info "  - jenkins-credentials.txt"
log_info ""
log_info "IMPORTANT:"
log_info "  1. Add credentials to Jenkins"
log_info "  2. DO NOT commit .credentials/ to Git"
log_info "  3. Store in secure location"
log_info ""
log_info "To test:"
log_info "  az login --service-principal -u <APP_ID> -p <PASSWORD> --tenant <TENANT_ID>"
log_info "=========================================="
