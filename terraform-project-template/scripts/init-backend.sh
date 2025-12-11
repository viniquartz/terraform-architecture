#!/bin/bash
# Inicializa backend do Terraform dinamicamente

set -e

PROJECT_NAME=${1}
ENVIRONMENT=${2}

if [ -z "$PROJECT_NAME" ] || [ -z "$ENVIRONMENT" ]; then
    echo "Uso: $0 <project-name> <environment>"
    echo "Exemplo: $0 my-project prd"
    exit 1
fi

# Validar ambiente
if [[ ! "$ENVIRONMENT" =~ ^(prd|qlt|tst)$ ]]; then
    echo "Ambiente invalido: $ENVIRONMENT"
    echo "Use: prd, qlt ou tst"
    exit 1
fi

# Configuracoes do backend
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="stterraformstate"
CONTAINER_NAME="terraform-state-${ENVIRONMENT}"
STATE_KEY="${PROJECT_NAME}/terraform.tfstate"

echo "[INFO] Inicializando backend"
echo "  Projeto: $PROJECT_NAME"
echo "  Ambiente: $ENVIRONMENT"
echo "  Container: $CONTAINER_NAME"
echo "  Key: $STATE_KEY"

# Criar arquivo de configuracao
cat > backend-config.tfbackend <<EOF
resource_group_name  = "$RESOURCE_GROUP"
storage_account_name = "$STORAGE_ACCOUNT"
container_name       = "$CONTAINER_NAME"
key                  = "$STATE_KEY"
EOF

echo "[INFO] Arquivo backend-config.tfbackend criado"

# Inicializar Terraform
terraform init -backend-config=backend-config.tfbackend -reconfigure

if [ $? -eq 0 ]; then
    echo "[OK] Backend inicializado"
else
    echo "[ERROR] Falha ao inicializar backend"
    exit 1
fi
