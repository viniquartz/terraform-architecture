# Terraform Azure POC

**Version:** 1.0 POC  
**Date:** December 2, 2025

---

## Objective

Proof of Concept (POC) to implement Infrastructure as Code (IaC) using Terraform on Azure.

## Repository Structure

```
terraform-azure-project/
├── README.md
├── docs/
│   └── README.md              # This file
├── pipelines/                 # Jenkins pipelines (future)
├── scripts/                   # Auxiliary scripts
├── terraform-modules/         # Reusable modules
│   ├── vnet/
│   ├── subnet/
│   ├── nsg/
│   ├── ssh/
│   └── vm-linux/
└── template/                  # Infrastructure template
    ├── providers.tf
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── environments/
        ├── prd/
        │   └── terraform.tfvars
        └── non-prd/
            └── terraform.tfvars
```

## Available Modules

### 1. VNET (Virtual Network)
Creates a virtual network in Azure.

**Inputs:**
- `vnet_name` - VNET name
- `location` - Azure region
- `resource_group_name` - Resource group name
- `address_space` - Address space (CIDR)
- `tags` - Tags for organization

**Outputs:**
- `vnet_id` - VNET ID
- `vnet_name` - VNET name

### 2. Subnet
Creates a subnet within the VNET.

**Inputs:**
- `subnet_name` - Subnet name
- `resource_group_name` - Resource group name
- `virtual_network_name` - VNET name
- `address_prefixes` - Address prefixes

**Outputs:**
- `subnet_id` - Subnet ID
- `subnet_name` - Subnet name

### 3. NSG (Network Security Group)
Creates a network security group.

**Inputs:**
- `nsg_name` - NSG name
- `location` - Azure region
- `resource_group_name` - Resource group name
- `subnet_id` - Subnet ID (optional)
- `tags` - Tags

**Outputs:**
- `nsg_id` - NSG ID
- `nsg_name` - NSG name

### 4. SSH Rule
Adds SSH rule to NSG.

**Inputs:**
- `rule_name` - Rule name
- `priority` - Priority (default: 1001)
- `source_address_prefix` - Source IP/CIDR
- `resource_group_name` - Resource group name
- `network_security_group_name` - NSG name

**Outputs:**
- `rule_id` - Rule ID
- `rule_name` - Rule name

### 5. VM Linux
Creates a Linux virtual machine.

**Inputs:**
- `vm_name` - VM name
- `location` - Azure region
- `resource_group_name` - Resource group name
- `vm_size` - VM size
- `admin_username` - Admin user
- `ssh_public_key` - SSH public key
- `subnet_id` - Subnet ID
- `enable_public_ip` - Enable public IP (true/false)
- `os_disk_type` - Disk type (Standard_LRS/Premium_LRS)
- `tags` - Tags

**Outputs:**
- `vm_id` - VM ID
- `vm_name` - VM name
- `private_ip_address` - Private IP
- `public_ip_address` - Public IP (if enabled)

## Quick Start

### 1. Prerequisites

```bash
# Azure CLI
az login

# Terraform
terraform version  # >= 1.5.0
```

### 2. Generate SSH key

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_vm_key
cat ~/.ssh/azure_vm_key.pub  # Copy content
```

### 3. Configure environment

Edit the variables file for the desired environment:

```bash
# Non-PRD
vim template/environments/non-prd/terraform.tfvars

# PRD
vim template/environments/prd/terraform.tfvars
```

Paste your SSH public key in the `ssh_public_key` field.

### 4. Deploy

```bash
cd template

# Initialize
terraform init

# Non-PRD
terraform plan -var-file="environments/non-prd/terraform.tfvars"
terraform apply -var-file="environments/non-prd/terraform.tfvars"

# PRD
terraform plan -var-file="environments/prd/terraform.tfvars"
terraform apply -var-file="environments/prd/terraform.tfvars"
```

### 5. Access VM

```bash
# Get public IP
terraform output vm_public_ip

# Connect via SSH
ssh -i ~/.ssh/azure_vm_key azureuser@<IP>
```

### 6. Destroy infrastructure

```bash
terraform destroy -var-file="environments/<env>/terraform.tfvars"
```

## Differences Between Environments

| Item | Non-PRD | PRD |
|------|---------|-----|
| **Region** | West US | East US |
| **VNET CIDR** | 10.1.0.0/16 | 10.0.0.0/16 |
| **Subnet CIDR** | 10.1.1.0/24 | 10.0.1.0/24 |
| **VM Size** | Standard_B2s (economical) | Standard_D2s_v3 (performance) |
| **Disk Type** | Standard_LRS | Premium_LRS |

## Best Practices

### Module Organization
- Each module in its own directory
- `main.tf` - Main resources
- `variables.tf` - Variable declaration
- `outputs.tf` - Module outputs

### Naming
- Use prefix for all resources: `${prefix}-<type>-${environment}`
- Examples: `myproject-vnet-prd`, `myproject-vm-non-prd`

### Variables
- Use variables for everything that can change between environments
- Provide default values when appropriate
- Document all variables

### Tags
- Always add tags to resources:
  - `Environment` - Environment (Production/Non-Production)
  - `ManagedBy` - Terraform
  - `Project` - Project name
  - `CostCenter` - Cost center

## Next Steps

This is a POC. Next steps include:

1. **Remote Backend** - Configure Azure Storage for state
2. **CI/CD** - Implement Jenkins pipelines
3. **Additional Modules** - Create more modules as needed
4. **Security** - Add security scanning (tfsec, checkov)
5. **Documentation** - Expand documentation as project grows

## Useful Commandss

```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# View current state
terraform show

# List resources
terraform state list

# View specific output
terraform output <name>

# View plan without applying
terraform plan

# Apply only one resource
terraform apply -target=module.vm
```

## Support

For questions or issues, consult:
- Documentacao oficial: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- Azure CLI: https://docs.microsoft.com/cli/azure/
