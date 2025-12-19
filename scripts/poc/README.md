# POC Scripts

Scripts for manual POC demonstration of Terraform deployment workflow.

## Purpose

These scripts are designed for **local testing and POC demonstrations only**. They simulate the workflow that will be automated in Jenkins pipelines but allow manual execution for learning and testing.

## Prerequisites

1. **Azure CLI installed and authenticated:**
   ```bash
   az login
   az account show
   ```

2. **Terraform installed:**
   ```bash
   terraform version
   ```

3. **Service Principal created:**
   ```bash
   # Create service principal for testing environment
   az ad sp create-for-rbac \
     --name "terraform-poc-sp" \
     --role Contributor \
     --scopes /subscriptions/<subscription-id>
   
   # Save output:
   # appId       -> ARM_CLIENT_ID
   # password    -> ARM_CLIENT_SECRET
   # tenant      -> ARM_TENANT_ID
   ```

4. **Backend storage created:**
   ```bash
   cd ../setup
   ./configure-azure-backend.sh
   ```

## Scripts Overview

| Script | Purpose | Prerequisites |
|--------|---------|---------------|
| `azure-login.sh` | Authenticate with Service Principal | ENV vars set |
| `configure.sh` | Configure backend, init, validate | Azure authenticated |
| `deploy.sh` | Generate plan and apply | configure.sh executed |
| `destroy.sh` | Generate destroy plan and apply | configure.sh executed |

## Complete Workflow

### 1. Set Environment Variables

```bash
# Export Azure credentials
export ARM_CLIENT_ID="xxx"
export ARM_CLIENT_SECRET="xxx"
export ARM_SUBSCRIPTION_ID="xxx"
export ARM_TENANT_ID="xxx"
```

### 2. Authenticate to Azure

```bash
cd scripts/poc
./azure-login.sh
```

**What it does:**
- Validates environment variables are set
- Authenticates Azure CLI with service principal
- Sets default subscription
- Exports variables for Terraform

### 3. Configure Terraform

```bash
./configure.sh mypoc tst ../../terraform-project-template
```

**Parameters:**
- `mypoc` - Project name
- `tst` - Environment (prd/qlt/tst)
- `../../terraform-project-template` - Path to Terraform workspace

**What it does:**
- Validates Azure CLI and Terraform installed
- Checks authentication status
- Validates backend resources exist
- Creates container if needed
- Generates `backend-config.tfbackend`
- Runs `terraform init`
- Runs `terraform fmt` and `terraform validate`

### 4. Deploy Infrastructure

```bash
./deploy.sh mypoc tst ../../terraform-project-template
```

**What it does:**
- Changes to workspace directory
- Runs `terraform plan` with environment variables
- Saves plan to `tfplan` file
- Prompts for approval
- Runs `terraform apply` with saved plan

**Auto-approve mode (skip confirmation):**
```bash
./deploy.sh mypoc tst ../../terraform-project-template --auto-approve
```

### 5. Verify Deployment

```bash
cd ../../terraform-project-template
terraform output
terraform state list
az resource list --resource-group "azr-tst-mypoc-rg-01" --output table
```

### 6. Destroy Resources

```bash
cd ../../scripts/poc
./destroy.sh mypoc tst ../../terraform-project-template
```

**What it does:**
- Prompts for confirmation ("yes" required)
- Changes to workspace directory
- Runs `terraform plan -destroy`
- Saves destroy plan to `tfplan-destroy`
- Prompts for approval
- Runs `terraform apply` with destroy plan
- Cleans up local files

**Auto-approve and delete state:**
```bash
./destroy.sh mypoc tst ../../terraform-project-template --auto-approve --delete-state
```

## Complete Example

```bash
# 1. Navigate to POC scripts
cd /path/to/terraform-azure-project/scripts/poc

# 2. Set credentials
export ARM_CLIENT_ID="xxx"
export ARM_CLIENT_SECRET="xxx"
export ARM_SUBSCRIPTION_ID="xxx"
export ARM_TENANT_ID="xxx"

# 3. Authenticate
./azure-login.sh

# 4. Configure
./configure.sh mypoc tst ../../terraform-project-template

# 5. Deploy
./deploy.sh mypoc tst ../../terraform-project-template

# 6. Verify
cd ../../terraform-project-template
terraform output

# 7. Return and destroy
cd ../../scripts/poc
./destroy.sh mypoc tst ../../terraform-project-template --auto-approve --delete-state
```

## Script Details

### azure-login.sh

```bash
./azure-login.sh
```

**Environment variables required:**
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`

**Output:**
- Azure CLI authenticated
- Subscription set
- Variables exported for Terraform

### configure.sh

```bash
./configure.sh <project-name> <environment> <workspace-path>
```

**Validations performed:**
- ✓ Azure CLI installed
- ✓ Azure authenticated
- ✓ Terraform installed
- ✓ Backend resource group exists
- ✓ Backend storage account exists
- ✓ Container exists (creates if not)
- ✓ Terraform configuration valid

**Creates:**
- `backend-config.tfbackend` in workspace directory
- `.terraform/` directory
- `.terraform.lock.hcl`

### deploy.sh

```bash
./deploy.sh <project-name> <environment> <workspace-path> [--auto-approve]
```

**Executes:**
1. `terraform plan` with environment variables
2. Saves plan to `tfplan`
3. Prompts for approval (unless --auto-approve)
4. `terraform apply tfplan`

**Output:**
- Resources created in Azure
- Outputs displayed
- Plan file saved

### destroy.sh

```bash
./destroy.sh <project-name> <environment> <workspace-path> [--auto-approve] [--delete-state]
```

**Options:**
- `--auto-approve`: Skip confirmation prompts
- `--delete-state`: Delete state file from Azure Storage after destroy

**Executes:**
1. Confirmation prompt ("yes" required)
2. `terraform plan -destroy`
3. Saves plan to `tfplan-destroy`
4. Prompts for approval (unless --auto-approve)
5. `terraform apply tfplan-destroy`
6. Optionally deletes state blob
7. Cleans up local files

**Cleans:**
- `tfplan-destroy`
- `backend-config.tfbackend`
- `.terraform/`
- `.terraform.lock.hcl`

## Differences from Jenkins Pipelines

| Aspect | POC Scripts | Jenkins Pipelines |
|--------|-------------|-------------------|
| Execution | Manual | Automated |
| Authentication | Service Principal (manual) | Credentials from Jenkins |
| Approval | Console prompt | Jenkins approval gate |
| Backend config | Generated by script | Generated by pipeline |
| Notifications | None | Teams/Dynatrace |
| Security scan | Manual (if needed) | Automated (Trivy) |
| Cost analysis | Manual (if needed) | Automated (Infracost) |
| Artifacts | Local files | Archived in Jenkins |

## Troubleshooting

### Error: Not authenticated

**Symptom:** `Not authenticated to Azure`

**Solution:**
```bash
./azure-login.sh
```

### Error: Backend not found

**Symptom:** `Resource group 'rg-terraform-backend' not found`

**Solution:**
```bash
cd ../setup
./configure-azure-backend.sh
```

### Error: Workspace path not found

**Symptom:** `Workspace path not found: ../../terraform-project-template`

**Solution:**
```bash
# Use absolute path or correct relative path
./configure.sh mypoc tst /full/path/to/terraform-project-template
```

### Error: State locked

**Symptom:** `Error acquiring the state lock`

**Solution:**
```bash
# Wait for lock to release, or force unlock
cd ../../terraform-project-template
terraform force-unlock <lock-id>
```

## Security Notes

### For POC/Testing
- Use dedicated service principal for testing
- Limit scope to test subscription
- Use short-lived credentials
- Never commit credentials to git

### Credentials Storage
- ❌ Never hardcode credentials in scripts
- ❌ Never commit credentials to repository
- ✅ Use environment variables
- ✅ Use Azure Key Vault (future)

## Next Steps

After POC validation:
1. Migrate workflow to Jenkins pipelines (already created)
2. Configure Jenkins credentials
3. Set up approval gates
4. Enable notifications (Teams/Dynatrace)
5. Archive POC scripts for reference

## Notes

- Scripts are for **demonstration purposes only**
- Production deployments use Jenkins pipelines
- Scripts assume backend already configured
- All scripts use bash (macOS/Linux/WSL compatible)
- Windows users: Use Git Bash or WSL

## Related Documentation

- [Pipeline Documentation](../../pipelines/README.md)
- [Backend Setup](../setup/configure-azure-backend.sh)
- [Docker Image](../../docker/README.md)
- [Project Template](../../terraform-project-template/README.md)
