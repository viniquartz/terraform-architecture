# Scripts Documentation

This directory contains setup and utility scripts for the Terraform Azure project.

## Setup Scripts

### configure-azure-backend.sh

**Purpose:** Creates Azure infrastructure required for Terraform remote state storage.

**What it does:**
- Creates Resource Group: `rg-terraform-backend`
- Creates Storage Account: `sttfbackend<unique>` (Standard_LRS)
- Creates 3 blob containers:
  - `terraform-state-prd` - Production state files
  - `terraform-state-qlt` - Quality/Staging state files
  - `terraform-state-tst` - Test/Development state files
- Enables soft delete (30 days retention)
- Enables versioning for state files
- Applies mandatory Azure tags

**When to use:**
- **First time setup** - Run once before any Terraform deployments
- After Azure subscription change
- To recreate backend infrastructure (if deleted)

**Prerequisites:**
- Azure CLI installed and logged in (`az login`)
- Contributor access to subscription
- 16 Azure tags prepared (as per company policy)

**Usage:**
```bash
cd scripts/setup
chmod +x configure-azure-backend.sh
./configure-azure-backend.sh
```

**Example output:**
```
Creating Resource Group: rg-terraform-backend
Creating Storage Account: sttfbackendxyz123
Creating container: terraform-state-prd
Creating container: terraform-state-qlt
Creating container: terraform-state-tst
✓ Backend configured successfully
```

**Configuration produced:**
```hcl
# Use in terraform backend configuration
resource_group_name  = "rg-terraform-backend"
storage_account_name = "sttfbackendxyz123"  # Shown in script output
container_name       = "terraform-state-<env>"  # prd, qlt, or tst
```

---

### create-service-principals.sh

**Purpose:** Creates Azure Service Principals with environment-specific RBAC permissions for Terraform automation.

**What it does:**
- Creates 3 Service Principals:
  - `sp-terraform-prd` - Production Contributor
  - `sp-terraform-qlt` - Quality/Staging Contributor
  - `sp-terraform-tst` - Test/Development Contributor
- Assigns Contributor role scoped to subscription
- Generates credentials (client ID, client secret, tenant ID)
- Outputs credentials for Jenkins configuration

**When to use:**
- **After backend setup** - Run once after `configure-azure-backend.sh`
- When rotating Service Principal credentials
- When setting up new Azure subscription
- To recreate SPs (if deleted or compromised)

**Prerequisites:**
- Azure CLI installed and logged in (`az login`)
- **Global Administrator** or **Application Administrator** role in Azure AD
- Contributor access to subscription
- Backend already configured (`configure-azure-backend.sh` completed)

**Usage:**
```bash
cd scripts/setup
chmod +x create-service-principals.sh
./create-service-principals.sh
```

**Important:** Script outputs sensitive credentials - save them securely immediately.

**Example output:**
```
Creating Service Principal: sp-terraform-prd
{
  "appId": "12345678-1234-1234-1234-123456789012",
  "password": "secretpassword123",
  "tenant": "87654321-4321-4321-4321-210987654321"
}

=== JENKINS CREDENTIALS ===
Configure these in Jenkins:
- azure-sp-prd-client-id: 12345678-1234-1234-1234-123456789012
- azure-sp-prd-client-secret: secretpassword123
- azure-sp-prd-subscription-id: abcdef...
- azure-sp-prd-tenant-id: 87654321-4321-4321-4321-210987654321
[... qlt and tst credentials ...]
```

**Jenkins Configuration:**
1. Go to Jenkins → Manage Jenkins → Credentials
2. Add credentials for each environment:
   - Type: Secret text
   - ID: `azure-sp-<env>-client-id` (exactly as shown)
   - Secret: Value from script output
3. Repeat for client-secret, subscription-id, tenant-id
4. Total: 12 credentials (4 per environment × 3 environments)

---

## Import Scripts

### generate-import-commands.sh

**Purpose:** Generates Terraform import commands for existing Azure resources.

**What it does:**
- Scans Azure Resource Groups for existing resources
- Generates `terraform import` commands
- Creates import script for bulk operations

**When to use:**
- Migrating existing Azure infrastructure to Terraform
- Adopting orphaned resources into Terraform management
- Recovering from state file loss

**Prerequisites:**
- Azure CLI installed and logged in
- Service Principal with Reader access to resources
- Terraform configuration already written for resources

**Usage:**
```bash
cd scripts/import
chmod +x generate-import-commands.sh
./generate-import-commands.sh <resource-group-name>
```

**Note:** Review generated commands before executing. Verify Terraform addresses match your configuration.

---

## Execution Order for New Setup

Follow this sequence for first-time setup:

1. **Configure Backend** (Run once)
   ```bash
   ./scripts/setup/configure-azure-backend.sh
   ```
   - Creates storage for Terraform state
   - Note the storage account name shown in output

2. **Create Service Principals** (Run once)
   ```bash
   ./scripts/setup/create-service-principals.sh
   ```
   - Creates automation accounts
   - Save credentials immediately to Jenkins

3. **Configure Jenkins** (Manual)
   - Add 12 credentials from script output
   - Test pipeline connection

4. **Initialize Project** (Per project)
   - Copy terraform-project-template
   - Configure backend in `backend-config.tfbackend`
   - Run `terraform init`

5. **Deploy via Jenkins** (Ongoing)
   - Use terraform-deploy-pipeline
   - Select environment (prd/qlt/tst)
   - Monitor drift with drift-detection-pipeline

---

## Troubleshooting

### configure-azure-backend.sh fails with "insufficient permissions"
**Solution:** Ensure you have Contributor role on subscription. Check with:
```bash
az role assignment list --assignee $(az account show --query user.name -o tsv)
```

### create-service-principals.sh hangs or fails
**Solution:**
- Check Azure AD permissions: Need Application Administrator role
- Try manual creation:
  ```bash
  az ad sp create-for-rbac --name "sp-terraform-tst" --role Contributor
  ```
- Verify no existing SP with same name

### Scripts fail in WSL with "cannot execute"
**Solution:** Fix line endings with dos2unix:
```bash
sudo apt install dos2unix
find scripts/ -type f -name "*.sh" -exec dos2unix {} \;
```

### Storage account name conflicts
**Solution:** Storage names must be globally unique. Script generates random suffix. If conflict occurs:
- Delete existing storage account with same name
- Or modify script to use different name pattern

### Service Principal credentials not working
**Solution:**
- Verify credentials copied correctly (no extra spaces)
- Check SP has Contributor role: `az role assignment list --assignee <client-id>`
- Allow ~5 minutes for Azure AD propagation
- Test authentication:
  ```bash
  az login --service-principal -u <client-id> -p <secret> --tenant <tenant-id>
  ```

---

## Security Notes

- **Never commit Service Principal credentials** to git
- Store credentials in Jenkins Credentials Manager only
- Rotate Service Principal secrets every 90 days
- Use separate SPs per environment (isolation)
- Backend Storage Account uses private endpoints (configure in Azure Portal)
- Enable Azure AD authentication for Storage in production

---

## Maintenance

### Rotate Service Principal Credentials
```bash
# Reset credential for SP
az ad sp credential reset --id <client-id>

# Update Jenkins with new secret
# Go to Jenkins → Credentials → Update azure-sp-<env>-client-secret
```

### Backup State Files
```bash
# Download all state files
for env in prd qlt tst; do
  az storage blob download-batch \
    --account-name sttfbackend<unique> \
    --source "terraform-state-$env" \
    --destination "./backup-$env"
done
```

### Verify Backend Health
```bash
# Check storage account
az storage account show --name sttfbackend<unique>

# List state files
az storage blob list \
  --account-name sttfbackend<unique> \
  --container-name terraform-state-prd \
  --output table
```

---

## Related Documentation

- [Architecture Plan](../docs/architecture-plan.md) - Overall strategy
- [Pipelines README](../pipelines/README.md) - Jenkins pipeline usage
- [Template README](../terraform-project-template/README.md) - Project template and testing
- [Runbook](../docs/runbook.md) - Operational procedures
- [Troubleshooting](../docs/troubleshooting.md) - Common issues
