# Windows VM Module

Módulo Terraform para criar uma VM Windows no Azure.

## Características

- ✅ Windows Server 2022 (default)
- ✅ Network Interface dedicada
- ✅ Suporte a Public IP (opcional)
- ✅ OS disk configurável
- ✅ Password authentication

## Uso

```hcl
module "vm_windows" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/vm-windows?ref=v1.0.0"
  
  name                = "azr-tst-myapp01-brs-vm-windows"
  resource_group_name = "azr-tst-myapp01-brs-rg"
  location            = "brazilsouth"
  vm_size             = "Standard_B2s"
  subnet_id           = module.subnet.id
  
  admin_username = "azureadmin"
  admin_password = "SecurePassword123!@#"
  
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 127
  }
  
  source_image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
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
| admin_username | Admin username | string | Não | azureadmin |
| admin_password | Admin password | string (sensitive) | Sim | - |
| public_ip_id | Public IP ID (optional) | string | Não | null |
| os_disk | OS disk configuration | object | Não | See below |
| source_image | Source image reference | object | Não | Windows Server 2022 |
| tags | Tags | map(string) | Não | {} |

**Default os_disk**:

```hcl
{
  caching              = "ReadWrite"
  storage_account_type = "Premium_LRS"
  disk_size_gb         = 127
}
```

**Default source_image**:

```hcl
{
  publisher = "MicrosoftWindowsServer"
  offer     = "WindowsServer"
  sku       = "2022-Datacenter"
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

## Imagens Windows Disponíveis

- **Windows Server 2022**: `2022-Datacenter`
- **Windows Server 2019**: `2019-Datacenter`
- **Windows 11**: `win11-22h2-pro`
- **Windows 10**: `win10-22h2-pro`
