#!/bin/bash
# Script to generate Terraform import commands for existing Azure resources

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Verifications
if ! command -v az &> /dev/null; then
    log_error "Azure CLI not installed"
    exit 1
fi

if ! az account show &> /dev/null; then
    log_error "Run: az login"
    exit 1
fi

RESOURCE_GROUP="${1}"

if [ -z "$RESOURCE_GROUP" ]; then
    log_error "Usage: $0 <resource-group-name>"
    exit 1
fi

# Check if RG exists
if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    log_error "Resource Group '$RESOURCE_GROUP' not found"
    exit 1
fi

log_info "Generating import commands for: $RESOURCE_GROUP"

OUTPUT_FILE="import-commands-${RESOURCE_GROUP}.sh"
TF_FILE="imported-resources-${RESOURCE_GROUP}.tf"

cat > "$OUTPUT_FILE" <<EOF
#!/bin/bash
# Import commands for Resource Group: $RESOURCE_GROUP
# Generated on: $(date)

set -e

echo "Starting resource import..."

EOF

cat > "$TF_FILE" <<EOF
# Imported resources from Resource Group: $RESOURCE_GROUP
# Generated on: $(date)
# ATTENTION: This is an initial template. Review and adjust as necessary.

EOF

# Virtual Networks
log_info "Searching for Virtual Networks..."
VNETS=$(az network vnet list --resource-group "$RESOURCE_GROUP" --query '[].{name:name,id:id}' -o json)

if [ "$(echo "$VNETS" | jq '. | length')" -gt 0 ]; then
    echo "$VNETS" | jq -r '.[] | @text "
# Virtual Network: \(.name)
resource "azurerm_virtual_network" "vnet_\(.name | gsub("-"; "_"))" {
  name                = "\(.name)"
  resource_group_name = "'$RESOURCE_GROUP'"
  # Complete with correct values after import
}

terraform import azurerm_virtual_network.vnet_\(.name | gsub("-"; "_")) \(.id)
"' | tee -a "$TF_FILE" >> "$OUTPUT_FILE"
fi

# Subnets
log_info "Searching for Subnets..."
for VNET_NAME in $(echo "$VNETS" | jq -r '.[].name'); do
    SUBNETS=$(az network vnet subnet list --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET_NAME" --query '[].{name:name,id:id}' -o json)
    
    echo "$SUBNETS" | jq -r '.[] | @text "
# Subnet: \(.name)
resource "azurerm_subnet" "subnet_\(.name | gsub("-"; "_"))" {
  name                 = "\(.name)"
  resource_group_name  = "'$RESOURCE_GROUP'"
  virtual_network_name = "'$VNET_NAME'"
  # Complete with address_prefixes after import
}

terraform import azurerm_subnet.subnet_\(.name | gsub("-"; "_")) \(.id)
"' | tee -a "$TF_FILE" >> "$OUTPUT_FILE"
done

# Network Security Groups
log_info "Buscando NSGs..."
NSGS=$(az network nsg list --resource-group "$RESOURCE_GROUP" --query '[].{name:name,id:id}' -o json)

echo "$NSGS" | jq -r '.[] | @text "
# NSG: \(.name)
resource \"azurerm_network_security_group\" \"nsg_\(.name | gsub("-"; "_"))\" {
  name                = \"\(.name)\"
  resource_group_name = \"'$RESOURCE_GROUP'\"
  location            = \"eastus\"  # Ajuste conforme necessário
}

terraform import azurerm_network_security_group.nsg_\(.name | gsub("-"; "_")) \(.id)
"' | tee -a "$TF_FILE" >> "$OUTPUT_FILE"

# Public IPs
log_info "Buscando Public IPs..."
PUBLIC_IPS=$(az network public-ip list --resource-group "$RESOURCE_GROUP" --query '[].{name:name,id:id}' -o json)

echo "$PUBLIC_IPS" | jq -r '.[] | @text "
# Public IPs
log_info "Searching for Public IPs..."

PUBLIC_IPS=$(az network public-ip list --resource-group "$RESOURCE_GROUP" --query '[].{name:name,id:id}' -o json)

echo "$PUBLIC_IPS" | jq -r '.[] | @text "
# Public IP: \(.name)
resource \"azurerm_public_ip\" \"pip_\(.name | gsub("-"; "_"))\" {
  name                = \"\(.name)\"
  resource_group_name = \"'$RESOURCE_GROUP'\"
  location            = \"eastus\"  # Adjust as necessary
  allocation_method   = \"Static\"  # Adjust as necessary
"' | tee -a "$TF_FILE" >> "$OUTPUT_FILE"

# Storage Accounts
log_info "Buscando Storage Accounts..."
STORAGE_ACCOUNTS=$(az storage account list --resource-group "$RESOURCE_GROUP" --query '[].{name:name,id:id}' -o json)

echo "$STORAGE_ACCOUNTS" | jq -r '.[] | @text "
# Storage Accounts
log_info "Searching for Storage Accounts..."

STORAGE_ACCOUNTS=$(az storage account list --resource-group "$RESOURCE_GROUP" --query '[].{name:name,id:id}' -o json)

echo "$STORAGE_ACCOUNTS" | jq -r '.[] | @text "
# Storage Account: \(.name)
resource \"azurerm_storage_account\" \"sa_\(.name | gsub("-"; "_"))\" {
  name                     = \"\(.name)\"
  resource_group_name      = \"'$RESOURCE_GROUP'\"
  location                 = \"eastus\"  # Adjust as necessary
  account_tier             = \"Standard\"  # Adjust as necessary
  account_replication_type = \"LRS\"  # Adjust as necessary
"' | tee -a "$TF_FILE" >> "$OUTPUT_FILE"

# Virtual Machines
log_info "Buscando Virtual Machines..."
VMS=$(az vm list --resource-group "$RESOURCE_GROUP" --query '[].{name:name,id:id}' -o json)

echo "$VMS" | jq -r '.[] | @text "
# VM: \(.name)
resource \"azurerm_linux_virtual_machine\" \"vm_\(.name | gsub("-"; "_"))\" {
  name                = \"\(.name)\"
  resource_group_name = \"'$RESOURCE_GROUP'\"
  location            = \"eastus\"  # Ajuste conforme necessário
  size                = \"Standard_B2s\"  # Ajuste conforme necessário
  # Complete com os demais atributos após import
}

terraform import azurerm_linux_virtual_machine.vm_\(.name | gsub("-"; "_")) \(.id)
"' | tee -a "$TF_FILE" >> "$OUTPUT_FILE"

# Key Vaults
log_info "Buscando Key Vaults..."
KEY_VAULTS=$(az keyvault list --resource-group "$RESOURCE_GROUP" --query '[].{name:name,id:id}' -o json)

echo "$KEY_VAULTS" | jq -r '.[] | @text "
# Key Vaults
log_info "Searching for Key Vaults..."

KEY_VAULTS=$(az keyvault list --resource-group "$RESOURCE_GROUP" --query '[].{name:name,id:id}' -o json)

echo "$KEY_VAULTS" | jq -r '.[] | @text "
# Key Vault: \(.name)
resource \"azurerm_key_vault\" \"kv_\(.name | gsub("-"; "_"))\" {
  name                = \"\(.name)\"
  resource_group_name = \"'$RESOURCE_GROUP'\"
  location            = \"eastus\"  # Adjust as necessary
  tenant_id           = \"TENANT_ID\"  # Replace
"' | tee -a "$TF_FILE" >> "$OUTPUT_FILE"

# Finalize script
cat >> "$OUTPUT_FILE" <<'EOF'

echo ""
echo " Import completed!"
echo ""
echo "Next steps:"
echo "1. Review and adjust resources in imported-resources-*.tf"
echo "2. Run: terraform plan"
echo "3. Refactor code to use modules"
EOF

chmod +x "$OUTPUT_FILE"

log_info ""
log_info "=========================================="
log_info " COMMANDS GENERATED SUCCESSFULLY"
log_info "=========================================="
log_info ""
log_info "Generated files:"
log_info "  1. $OUTPUT_FILE - Import script"
log_info "  2. $TF_FILE - Resource definitions"
log_info ""
log_info "Resources found:"
log_info "  - Virtual Networks: $(echo "$VNETS" | jq '. | length')"
log_info "  - NSGs: $(echo "$NSGS" | jq '. | length')"
log_info "  - Public IPs: $(echo "$PUBLIC_IPS" | jq '. | length')"
log_info "  - Storage Accounts: $(echo "$STORAGE_ACCOUNTS" | jq '. | length')"
log_info "  - VMs: $(echo "$VMS" | jq '. | length')"
log_info "  - Key Vaults: $(echo "$KEY_VAULTS" | jq '. | length')"
log_info ""
log_info "To execute the import:"
log_info "  ./$OUTPUT_FILE"
log_info ""
