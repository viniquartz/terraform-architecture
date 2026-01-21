# Linux VM Module

Módulo Terraform para criar uma VM Linux no Azure.

## Características

- ✅ Ubuntu 22.04 LTS (default)
- ✅ Network Interface dedicada
- ✅ Suporte a Public IP (opcional)
- ✅ OS disk configurável
- ✅ SSH authentication

## Uso

```hcl
module "vm_linux" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/vm-linux?ref=v1.0.0"
  
  name                = "azr-tst-myapp01-brs-vm-linux"
  resource_group_name = "azr-tst-myapp01-brs-rg"
  location            = "brazilsouth"
  vm_size             = "Standard_B2s"
  subnet_id           = module.subnet.id
  
  admin_username = "azureuser"
  admin_ssh_key  = "ssh-rsa AAAAB3... user@example.com"
  
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 30
  }
  
  source_image = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  
  tags = {
    Environment = "tst"
  }
}
```

## Inputs

| Nome | Descrição | Tipo | Obrigatório | Default |
|------|-----------|------|-------------|---------|
| name | VM name | string | Sim | - |
| resource_group_name | Resource Group name | string | Sim | - |
| location | Azure region | string | Sim | - |
| vm_size | VM size | string | Não | Standard_B2s |
| subnet_id | Subnet ID | string | Sim | - |
| admin_username | Admin username | string | Não | azureuser |
| admin_ssh_key | SSH public key | string (sensitive) | Sim | - |
| public_ip_id | Public IP ID (optional) | string | Não | null |
| os_disk | OS disk configuration | object | Não | See below |
| source_image | Source image reference | object | Não | Ubuntu 22.04 LTS |
| tags | Tags | map(string) | Não | {} |

**Default os_disk**:

```hcl
{
  caching              = "ReadWrite"
  storage_account_type = "Premium_LRS"
  disk_size_gb         = 30
}
```

**Default source_image**:

```hcl
{
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts-gen2"
  version   = "latest"
}
```

## Outputs

| Nome | Descrição |
|------|-----------|
| id | VM ID |
| name | VM name |
| private_ip_address | VM private IP |
| public_ip_address | VM public IP (if assigned) |
| network_interface_id | Network Interface ID |

## Imagens Linux Disponíveis

- **Ubuntu 22.04 LTS**: `22_04-lts-gen2`
- **Ubuntu 20.04 LTS**: `20_04-lts-gen2`
- **Red Hat 8**: `8-lvm-gen2`
- **CentOS 7**: `7-lvm-gen2`

  # OS Disk

  os_disk_size_gb     = 128
  os_disk_caching     = "ReadWrite"
  os_disk_storage_type = "Premium_LRS"
  
  # Source Image

  source_image_publisher = "Canonical"
  source_image_offer     = "0001-com-ubuntu-server-jammy"
  source_image_sku       = "22_04-lts-gen2"
  source_image_version   = "latest"
  
  # Additional Configuration

  enable_boot_diagnostics = true
  
  tags = local.common_tags
}

# Add data disks

resource "azurerm_managed_disk" "data" {
  name                 = "${module.vm_app.name}-data"
  location             = var.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 512
  
  tags = local.common_tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  managed_disk_id    = azurerm_managed_disk.data.id
  virtual_machine_id = module.vm_app.id
  lun                = 0
  caching            = "ReadWrite"
}

```

### Multiple VMs with Count

```hcl
module "vm_web" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/vm?ref=v1.0.0"
  count  = 3
  
  name                = "${module.naming.virtual_machine}${format("%02d", count.index + 1)}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  vm_size             = "Standard_B2s"
  subnet_id           = module.vnet.subnet_ids["web"]
  admin_ssh_key       = var.admin_ssh_key
  
  tags = merge(
    local.common_tags,
    {
      Instance = format("%02d", count.index + 1)
    }
  )
}
```

### With Static Private IP

```hcl
module "vm_db" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/vm?ref=v1.0.0"
  
  name                     = "${module.naming.virtual_machine}-db"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  vm_size                  = "Standard_D2s_v3"
  subnet_id                = module.vnet.subnet_ids["database"]
  admin_ssh_key            = var.admin_ssh_key
  private_ip_address       = "10.0.2.10"
  private_ip_address_allocation = "Static"
  
  tags = local.common_tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Virtual Machine name | string | - | yes |
| resource_group_name | Resource Group name | string | - | yes |
| location | Azure region | string | - | yes |
| vm_size | VM size | string | - | yes |
| subnet_id | Subnet ID for NIC | string | - | yes |
| admin_ssh_key | SSH public key | string | - | yes |
| admin_username | Admin username | string | adminuser | no |
| os_disk_size_gb | OS disk size in GB | number | 30 | no |
| os_disk_caching | OS disk caching | string | ReadWrite | no |
| os_disk_storage_type | OS disk storage type | string | Standard_LRS | no |
| source_image_publisher | Image publisher | string | Canonical | no |
| source_image_offer | Image offer | string | 0001-com-ubuntu-server-jammy | no |
| source_image_sku | Image SKU | string | 22_04-lts-gen2 | no |
| source_image_version | Image version | string | latest | no |
| private_ip_address | Private IP address | string | null | no |
| private_ip_address_allocation | IP allocation method | string | Dynamic | no |
| enable_boot_diagnostics | Enable boot diagnostics | bool | false | no |
| tags | Tags to apply to resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Virtual Machine ID |
| name | Virtual Machine name |
| private_ip_address | Private IP address |
| network_interface_id | Network Interface ID |

## VM Sizes

### Development/POC

| Size | vCPUs | RAM | Cost/Month |
|------|-------|-----|------------|
| Standard_B1s | 1 | 1 GB | Low |
| Standard_B2s | 2 | 4 GB | Low |
| Standard_B2ms | 2 | 8 GB | Medium |

### Production

| Size | vCPUs | RAM | Use Case |
|------|-------|-----|----------|
| Standard_D2s_v3 | 2 | 8 GB | General purpose |
| Standard_D4s_v3 | 4 | 16 GB | General purpose |
| Standard_E4s_v3 | 4 | 32 GB | Memory intensive |
| Standard_F4s_v2 | 4 | 8 GB | Compute intensive |

[Full VM sizes list](https://learn.microsoft.com/azure/virtual-machines/sizes)

## Disk Types

| Type | Performance | Use Case | Cost |
|------|-------------|----------|------|
| Standard_LRS | Basic | Dev/Test | Low |
| StandardSSD_LRS | Medium | General workloads | Medium |
| Premium_LRS | High | Production | High |
| Premium_ZRS | High + Redundancy | Critical workloads | Highest |

## Common Linux Images

### Ubuntu

```hcl
source_image_publisher = "Canonical"
source_image_offer     = "0001-com-ubuntu-server-jammy"
source_image_sku       = "22_04-lts-gen2"
source_image_version   = "latest"
```

### Red Hat Enterprise Linux

```hcl
source_image_publisher = "RedHat"
source_image_offer     = "RHEL"
source_image_sku       = "9_2"
source_image_version   = "latest"
```

### CentOS

```hcl
source_image_publisher = "OpenLogic"
source_image_offer     = "CentOS"
source_image_sku       = "8_5-gen2"
source_image_version   = "latest"
```

### Debian

```hcl
source_image_publisher = "Debian"
source_image_offer     = "debian-11"
source_image_sku       = "11-gen2"
source_image_version   = "latest"
```

## SSH Key Generation

```bash
# Generate new SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_vm -C "azure-vm-key"

# Get public key
cat ~/.ssh/azure_vm.pub
```

Use in Terraform:

```hcl
variable "admin_ssh_key" {
  description = "SSH public key for VM admin user"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ..."
}
```

## Connect to VM

```bash
# Using private IP (from bastion or VPN)
ssh adminuser@10.0.1.10 -i ~/.ssh/azure_vm

# Using public IP (if assigned)
ssh adminuser@<public-ip> -i ~/.ssh/azure_vm
```

## Security Best Practices

### For POC/Development

- Use B-series VMs (burstable, cost-effective)
- Standard_LRS disks (cheapest)
- Dynamic IP assignment
- Boot diagnostics disabled (no storage cost)

### For Production

- Use appropriate VM size for workload
- Premium_LRS or Premium_ZRS disks
- Static IP for databases
- Enable boot diagnostics
- Implement backup strategy
- Use availability sets/zones
- Enable Azure Monitor
- Configure update management

Example production configuration:

```hcl
module "vm_production" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/vm?ref=v1.0.0"
  
  name                = module.naming.virtual_machine
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  
  # Production VM size
  vm_size = "Standard_D4s_v3"
  
  # Network
  subnet_id                     = module.vnet.subnet_ids["app"]
  private_ip_address            = "10.0.1.10"
  private_ip_address_allocation = "Static"
  
  # Authentication
  admin_username = "azureadmin"
  admin_ssh_key  = var.admin_ssh_key
  
  # Premium disk
  os_disk_size_gb      = 128
  os_disk_storage_type = "Premium_LRS"
  
  # Monitoring
  enable_boot_diagnostics = true
  
  tags = merge(
    local.common_tags,
    {
      Tier = "Application"
      Backup = "Daily"
    }
  )
}
```

## High Availability

### Availability Set

```hcl
resource "azurerm_availability_set" "main" {
  name                = "${module.naming.availability_set}-app"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  managed             = true
  
  tags = local.common_tags
}

module "vm" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/vm?ref=v1.0.0"
  count  = 3
  
  name                = "${module.naming.virtual_machine}${format("%02d", count.index + 1)}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  vm_size             = "Standard_D2s_v3"
  subnet_id           = module.vnet.subnet_ids["app"]
  admin_ssh_key       = var.admin_ssh_key
  availability_set_id = azurerm_availability_set.main.id
  
  tags = local.common_tags
}
```

## Notes

- VM names must be 1-64 characters (alphanumeric, underscore, hyphen, period)
- Admin username cannot be root, admin, administrator
- SSH key is mandatory (no password authentication)
- NIC is automatically created and managed by module
- Boot diagnostics requires storage account (created automatically if enabled)

## Common Issues

### Issue: SSH key rejected

**Error:** `Permission denied (publickey)`

**Solution:**

1. Verify SSH key format (must start with ssh-rsa)
2. Check private key permissions: `chmod 600 ~/.ssh/azure_vm`
3. Verify correct username (default: adminuser)

### Issue: VM size not available

**Error:** `The requested VM size Standard_D4s_v3 is not available`

**Solution:**

1. Check region availability
2. Try different VM size
3. Verify subscription quota

### Issue: Disk size too small

**Error:** `OS disk size cannot be less than the image`

**Solution:** Increase `os_disk_size_gb` to at least 30 GB

## Migration from Old Structure

Old path: `modules/vm`
New path: `modules/compute/vm`

Update your module sources:

```hcl
# Old
module "vm" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/vm?ref=v1.0.0"
}

# New
module "vm" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/vm?ref=v2.0.0"
}
```
