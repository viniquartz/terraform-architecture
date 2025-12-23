# POC Scripts

Scripts for manual testing and local demonstration of Terraform workflow.

**Note: For POC/local testing only. CI/CD pipelines execute Terraform directly.**

## Prerequisites

1. **Azure Credentials** (Service Principal)
2. **GitLab Token** (Personal Access Token with `read_repository`)
3. **Azure Backend** configured (Storage Account + Container)
4. **Docker** (optional - for isolated environment)

## Available Scripts

| Script | Purpose |
|--------|---------|
| `azure-login.sh` | Authenticate Azure CLI with Service Principal |
| `configure.sh` | Clone repository and configure Terraform backend |
| `validate-modules.sh` | Validate Terraform modules |
| `deploy.sh` | Generate plan and apply changes |
| `destroy.sh` | Generate destroy plan and remove resources |

## Complete Workflow

### 1. Configure Environment Variables

```bash
# Azure credentials (Service Principal)
export ARM_CLIENT_ID="xxx"
export ARM_CLIENT_SECRET="xxx"
export ARM_SUBSCRIPTION_ID="xxx"
export ARM_TENANT_ID="xxx"

# GitLab token
export GITLAB_TOKEN="glpat-xxxxxxxxxxxxxxxxxxxx"
```

### 2. Authenticate Azure

```bash
bash scripts/poc/azure-login.sh
```

Validates credentials and authenticates Azure CLI.

### 3. Configure Project

```bash
bash scripts/poc/configure.sh myapp tst https://gitlab.com/yourgroup/terraform-project-template.git
```

**Parameters:**

- `myapp` - Project name
- `tst` - Environment (tst/qlt/prd)
- `<url>` - GitLab repository URL

**What it does:**

- Clones repository from GitLab
- Configures Terraform backend
- Executes `terraform init`

**Creates:**

- Directory `myapp/` with project code
- File `myapp/backend-config.tfbackend`

### 4. (Optional) Validate Modules

```bash
bash scripts/poc/validate-modules.sh https://gitlab.com/yourgroup/terraform-modules.git v1.0.0
```

Validates all Terraform modules from repository.

### 5. Deploy

```bash
bash scripts/poc/deploy.sh myapp tst
```

**What it does:**

1. Generates plan: `terraform plan -out=tfplan-tst.out`
2. Shows plan summary
3. Requests confirmation (`yes`)
4. Applies: `terraform apply tfplan-tst.out`

**Note: Always requires manual confirmation (`yes`)**

### 6. Destroy

```bash
bash scripts/poc/destroy.sh myapp tst
```

**What it does:**

1. Lists current resources
2. Generates destroy plan: `terraform plan -destroy -out=tfplan-destroy-tst.out`
3. Shows summary
4. Requests confirmation (`yes`)
5. Applies: `terraform apply tfplan-destroy-tst.out`

**Note: Always requires manual confirmation (`yes`)**

## Complete Example

```bash
# 1. Configure credentials
export ARM_CLIENT_ID="xxx"
export ARM_CLIENT_SECRET="xxx"
export ARM_SUBSCRIPTION_ID="xxx"
export ARM_TENANT_ID="xxx"
export GITLAB_TOKEN="glpat-xxx"

# 2. Authenticate Azure
bash scripts/poc/azure-login.sh

# 3. Configure project
bash scripts/poc/configure.sh myapp tst https://gitlab.com/yourgroup/terraform-project-template.git

# 4. (Optional) Validate modules
bash scripts/poc/validate-modules.sh https://gitlab.com/yourgroup/terraform-modules.git v1.0.0

# 5. Deploy
bash scripts/poc/deploy.sh myapp tst
# Answer: yes

# 6. Verify
cd myapp
terraform output
terraform state list

# 7. Destroy
cd ..
bash scripts/poc/destroy.sh myapp tst
# Answer: yes
```

## Usage with Docker

```bash
# Start container
docker run -it --rm \
  -e ARM_CLIENT_ID \
  -e ARM_CLIENT_SECRET \
  -e ARM_SUBSCRIPTION_ID \
  -e ARM_TENANT_ID \
  -e GITLAB_TOKEN \
  -v $(pwd):/workspace \
  -w /workspace \
  jenkins-terraform:latest bash

# Inside container
bash scripts/poc/azure-login.sh
bash scripts/poc/configure.sh myapp tst https://gitlab.com/...
bash scripts/poc/deploy.sh myapp tst
```

## Script Details

### azure-login.sh

```bash
bash scripts/poc/azure-login.sh
```

**Requires:**

- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_SUBSCRIPTION_ID`
- `ARM_TENANT_ID`

**Actions:**

- Validates environment variables
- Authenticates `az login` with Service Principal
- Sets default subscription

### configure.sh

```bash
bash scripts/poc/configure.sh <project-name> <environment> <gitlab-repo-url>
```

**Example:**

```bash
bash scripts/poc/configure.sh myapp tst https://gitlab.com/yourgroup/terraform-project-template.git
```

**Requires:**

- `GITLAB_TOKEN` environment variable

**Actions:**

1. Clones GitLab repository to `<project-name>/`
2. Generates `backend-config.tfbackend`
3. Executes `terraform init`

**Creates:**

- `myapp/` - Project directory
- `myapp/backend-config.tfbackend`
- `myapp/.terraform/`

### validate-modules.sh

```bash
bash scripts/poc/validate-modules.sh <gitlab-repo-url> [tag-or-branch]
```

**Examples:**

```bash
bash scripts/poc/validate-modules.sh https://gitlab.com/yourgroup/terraform-modules.git v1.0.0
bash scripts/poc/validate-modules.sh https://gitlab.com/yourgroup/terraform-modules.git main
```

**Actions:**

- Clones modules repository
- Discovers all modules
- Validates each module:
  - `terraform fmt -check`
  - `terraform init`
  - `terraform validate`
- Generates validation report

### deploy.sh

```bash
bash scripts/poc/deploy.sh <project-name> <environment>
```

**Example:**

```bash
bash scripts/poc/deploy.sh myapp tst
```

**Actions:**

1. Changes to `<project-name>/` directory
2. Executes `terraform plan -var-file=environments/<env>/terraform.tfvars -out=tfplan-<env>.out`
3. Shows plan summary
4. Requests confirmation: `Do you want to apply these changes? (yes/no):`
5. Executes `terraform apply tfplan-<env>.out`
6. Removes plan file after success

**Note: No --auto-approve flag, always requires manual `yes`**

### destroy.sh

```bash
bash scripts/poc/destroy.sh <project-name> <environment>
```

**Example:**

```bash
bash scripts/poc/destroy.sh myapp tst
```

**Actions:**

1. Changes to `<project-name>/` directory
2. Lists resources: `terraform state list`
3. Executes `terraform plan -destroy -var-file=... -out=tfplan-destroy-<env>.out`
4. Shows summary
5. Requests confirmation: `Type 'yes' to confirm destruction:`
6. Executes `terraform apply tfplan-destroy-<env>.out`
7. Removes plan file after success

**Note: No --auto-approve flag, always requires manual `yes`**

## Important Notes

1. **GitLab Token**: Required to clone private repositories and download modules
2. **Manual confirmation**: Deploy and Destroy always require confirmation
3. **Plan files**: Saved as `tfplan-<env>.out` and `tfplan-destroy-<env>.out`
4. **CI/CD**: Jenkins pipelines do not use these scripts, they execute Terraform directly
5. **State file**: Remains in Azure Storage after destroy (for audit purposes)
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
