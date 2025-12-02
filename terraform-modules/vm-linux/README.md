# Azure Linux Virtual Machine Module

Terraform module to create an Azure Linux Virtual Machine with SSH authentication.

## Usage

```hcl
module "vm" {
  source = "../../terraform-modules/vm-linux"

  vm_name             = "my-vm"
  location            = "West Europe"
  resource_group_name = "my-rg"
  subnet_id           = module.subnet.subnet_id
  vm_size             = "Standard_B2s"
  admin_username      = "azureuser"
  ssh_public_key      = file("~/.ssh/id_rsa.pub")
  enable_public_ip    = true

  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.0 |

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| vm_name | Name of the virtual machine | `string` | yes | - |
| location | Azure region | `string` | yes | - |
| resource_group_name | Name of the resource group | `string` | yes | - |
| subnet_id | ID of the subnet where the VM will be placed | `string` | yes | - |
| ssh_public_key | SSH public key for authentication | `string` | yes | - |
| vm_size | Size of the virtual machine | `string` | no | `Standard_B1s` |
| admin_username | Admin username for the VM | `string` | no | `azureuser` |
| enable_public_ip | Enable public IP for the VM | `bool` | no | `false` |
| public_ip_allocation_method | Public IP allocation method (Static or Dynamic) | `string` | no | `Static` |
| public_ip_sku | Public IP SKU (Basic or Standard) | `string` | no | `Standard` |
| os_disk_type | OS disk storage account type | `string` | no | `Standard_LRS` |
| image_publisher | VM image publisher | `string` | no | `Canonical` |
| image_offer | VM image offer | `string` | no | `0001-com-ubuntu-server-jammy` |
| image_sku | VM image SKU | `string` | no | `22_04-lts-gen2` |
| image_version | VM image version | `string` | no | `latest` |
| tags | Tags to apply to resources | `map(string)` | no | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| vm_id | The ID of the virtual machine |
| vm_name | The name of the virtual machine |
| private_ip_address | The private IP address of the VM |
| public_ip_address | The public IP address of the VM (null if disabled) |
| network_interface_id | The ID of the network interface |
| ssh_command | SSH command to connect to the VM |
| admin_username | The admin username for the VM |

## Security Features

- Password authentication is disabled (SSH keys only)
- VM size defaults to most affordable option (Standard_B1s)
- Ubuntu 22.04 LTS by default

## Validation Rules

- VM size must start with 'Standard_'
- Public IP allocation method must be 'Static' or 'Dynamic'
- Public IP SKU must be 'Basic' or 'Standard'
