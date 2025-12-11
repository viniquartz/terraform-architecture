# Terraform Project Template

Template for Terraform projects with dynamic backend on Azure.

## What's Included

```
terraform-project-template/
├── backend.tf          # Empty backend (dynamic)
├── providers.tf        # Azure provider
├── variables.tf        # Standard variables
├── main.tf             # Example: Resource Group
├── outputs.tf          # Basic outputs
├── scripts/
│   ├── init-backend.sh # Initialize backend
│   └── deploy.sh       # Complete deploy
└── .gitignore          # Files to ignore
```

## How to Use for POC

### 1. Copy Template

```bash
# Copy to your project
cp -r terraform-project-template ../my-project
cd ../my-project
```

### 2. Configure Azure Credentials

```bash
# Export Service Principal credentials
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_TENANT_ID="your-tenant-id"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
```

### 3. Deploy

```bash
# Grant permissions to scripts
chmod +x scripts/*.sh

# Deploy to TST
./scripts/deploy.sh my-project tst

# Deploy to PRD
./scripts/deploy.sh my-project prd
```

## What to Change

### 1. main.tf
Add your Azure resources here. The example only has Resource Group.

### 2. variables.tf
Add project-specific variables.

### 3. outputs.tf
Add outputs you need to expose.

### 4. backend.tf
DO NOT CHANGE. It's configured automatically by scripts.

## Backend Storage

State will be saved to:
- **Storage Account**: stterraformstate
- **Resource Group**: rg-terraform-state
- **Container**: terraform-state-{environment}
- **Key**: {project-name}/terraform.tfstate

Example:
- TST: terraform-state-tst/my-project/terraform.tfstate
- PRD: terraform-state-prd/my-project/terraform.tfstate

## Useful Commands

```bash
# View outputs
terraform output

# View resources in state
terraform state list

# Format code
terraform fmt -recursive

# Validate
terraform validate

# Destroy (careful!)
terraform destroy -var="environment=tst" -var="project_name=my-project"
```

## Troubleshooting

### Error: Backend not initialized
```bash
./scripts/init-backend.sh my-project tst
```

### Error: Invalid credentials
```bash
# Check if logged in
az account show

# Or use credentials via variables
export ARM_CLIENT_ID=...
```

### Error: Container does not exist
Run setup script first:
```bash
../../scripts/setup/configure-azure-backend.sh
```

## File Structure

- **backend.tf**: Dynamic backend (empty)
- **providers.tf**: Azure provider version ~> 3.0
- **variables.tf**: environment, project_name, location
- **main.tf**: Your resources (start with Resource Group)
- **outputs.tf**: Values to expose
- **scripts/init-backend.sh**: Initialize backend dynamically
- **scripts/deploy.sh**: Complete deploy (init + plan + apply)
