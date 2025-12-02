# Terraform Azure POC Template

This template creates a complete infrastructure setup with:
- Virtual Network
- Subnet
- Network Security Group
- SSH Security Rule
- Linux Virtual Machine

## Prerequisites

- Azure CLI installed and authenticated
- Terraform >= 1.5.0
- SSH key pair generated

## Directory Structure

```
template/
├── providers.tf           # Provider configuration
├── main.tf               # Main infrastructure code
├── variables.tf          # Variable declarations
├── outputs.tf            # Output definitions
└── environments/
    ├── prd/
    │   └── terraform.tfvars    # Production configuration
    └── non-prd/
        └── terraform.tfvars    # Non-production configuration
```

## Usage

### 1. Generate SSH Key (if needed)

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_vm_key
```

### 2. Update Configuration

Edit the appropriate environment file and replace the SSH public key:

```bash
# For production
vim environments/prd/terraform.tfvars

# For non-production
vim environments/non-prd/terraform.tfvars
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Deploy Infrastructure

**For Non-Production:**
```bash
terraform plan -var-file="environments/non-prd/terraform.tfvars"
terraform apply -var-file="environments/non-prd/terraform.tfvars"
```

**For Production:**
```bash
terraform plan -var-file="environments/prd/terraform.tfvars"
terraform apply -var-file="environments/prd/terraform.tfvars"
```

### 5. Access the VM

```bash
# Get the public IP
terraform output vm_public_ip

# SSH into the VM
ssh -i ~/.ssh/azure_vm_key azureuser@<vm_public_ip>
```

### 6. Destroy Infrastructure

```bash
terraform destroy -var-file="environments/<env>/terraform.tfvars"
```

## Environment Differences

| Configuration | Non-PRD | PRD |
|--------------|---------|-----|
| Location | West US | East US |
| VM Size | Standard_B2s | Standard_D2s_v3 |
| Disk Type | Standard_LRS | Premium_LRS |
| VNET CIDR | 10.1.0.0/16 | 10.0.0.0/16 |
| Subnet CIDR | 10.1.1.0/24 | 10.0.1.0/24 |

## Modules Used

All modules are located in `../terraform-modules/`:
- **vnet** - Virtual Network
- **subnet** - Subnet
- **nsg** - Network Security Group
- **ssh** - SSH Security Rule
- **vm-linux** - Linux Virtual Machine

## Outputs

After deployment, the following outputs are available:
- `resource_group_name` - Name of the resource group
- `vnet_id` - Virtual network ID
- `subnet_id` - Subnet ID
- `nsg_id` - Network security group ID
- `vm_id` - Virtual machine ID
- `vm_private_ip` - VM private IP address
- `vm_public_ip` - VM public IP address

## Customization

Modify variables in `terraform.tfvars` to customize:
- Resource naming prefix
- Network ranges
- VM size and disk type
- SSH access restrictions
- Tags for resource organization
