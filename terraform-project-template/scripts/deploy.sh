#!/bin/bash
# Deploy completo: init + plan + apply

set -e

PROJECT_NAME=${1}
ENVIRONMENT=${2}
AUTO_APPROVE=${3}

if [ -z "$PROJECT_NAME" ] || [ -z "$ENVIRONMENT" ]; then
    echo "Uso: $0 <project-name> <environment> [--auto-approve]"
    echo "Exemplo: $0 my-project prd"
    exit 1
fi

echo "[INFO] Deploy de $PROJECT_NAME em $ENVIRONMENT"

# Inicializar backend
./scripts/init-backend.sh "$PROJECT_NAME" "$ENVIRONMENT"

# Planejar
echo "[INFO] Gerando plano"
terraform plan \
    -var="environment=$ENVIRONMENT" \
    -var="project_name=$PROJECT_NAME" \
    -out=tfplan

# Aplicar
if [ "$AUTO_APPROVE" = "--auto-approve" ]; then
    echo "[INFO] Aplicando mudancas (auto-approve)"
    terraform apply -auto-approve tfplan
else
    echo "[INFO] Aplicando mudancas"
    terraform apply tfplan
fi

if [ $? -eq 0 ]; then
    echo "[OK] Deploy concluido"
else
    echo "[ERROR] Deploy falhou"
    exit 1
fi
