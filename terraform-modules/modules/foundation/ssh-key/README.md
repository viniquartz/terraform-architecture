# SSH Public Key Module

Terraform module to create and manage Azure SSH Public Key resource.

## Features

- Store SSH public keys in Azure
- Reference keys across VMs
- Centralized key management

## Usage

### Basic Example

```hcl
module "ssh_key" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/foundation/ssh-key?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-ssh"
  resource_group_name = module.rg.name
  location            = var.location
  public_key          = file("~/.ssh/id_rsa.pub")
  
  tags = local.common_tags
}
```

### Use with VM Module

```hcl
module "ssh_key" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/foundation/ssh-key?ref=v1.0.0"
  
  name                = "azr-prd-myapp01-weu-ssh"
  resource_group_name = module.rg.name
  location            = "westeurope"
  public_key          = var.admin_ssh_public_key
  
  tags = local.common_tags
}

module "vm_linux" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/vm-linux?ref=v1.0.0"
  
  name                = "azr-prd-myapp01-weu-vm-web"
  resource_group_name = module.rg.name
  location            = "westeurope"
  subnet_id           = module.subnet.id
  
  admin_username = "azureuser"
  admin_ssh_key  = module.ssh_key.public_key
  
  tags = local.common_tags
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| name | SSH Key name | string | Yes |
| resource_group_name | Resource Group name | string | Yes |
| location | Azure region | string | Yes |
| public_key | SSH public key content | string (sensitive) | Yes |
| tags | Tags to apply | map(string) | No (default: {}) |

## Outputs

| Name | Description |
|------|-------------|
| id | SSH Key ID |
| name | SSH Key name |
| public_key | SSH public key content (sensitive) |

## Generate SSH Key

```bash
# Generate new SSH key pair
ssh-keygen -t rsa -b 4096 -C "your@email.com" -f ~/.ssh/azure_vm

# Read public key
cat ~/.ssh/azure_vm.pub
```

## Multiple Keys Example

```hcl
locals {
  ssh_keys = {
    admin = file("~/.ssh/admin.pub")
    dev   = file("~/.ssh/dev.pub")
  }
}

module "ssh_keys" {
  source   = "git@github.com:org/terraform-azure-modules.git//modules/foundation/ssh-key?ref=v1.0.0"
  for_each = local.ssh_keys
  
  name                = "azr-prd-myapp01-weu-ssh-${each.key}"
  resource_group_name = module.rg.name
  location            = "westeurope"
  public_key          = each.value
  
  tags = local.common_tags
}
```
