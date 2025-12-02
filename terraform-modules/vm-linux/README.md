# Azure Linux Virtual Machine Module

Terraform module to create an Azure Linux Virtual Machine with SSH authentication.

## Description

This module creates a Linux VM in Azure with SSH-only authentication (password authentication is disabled for security). It includes network interface, optional public IP, and OS disk configuration.

## Usage

### Basic VM (Private IP only)

```hcl
module "vm" {
  source = "../../terraform-modules/vm-linux"

  vm_name             = "my-vm"
  location            = "West Europe"
  resource_group_name = "my-rg"
  subnet_id           = module.subnet.subnet_id
  ssh_public_key      = file("~/.ssh/id_rsa.pub")

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### VM with Public IP

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

## Examples

See [examples/basic](examples/basic) for a complete working example.

## Notes

- **SSH authentication only** - Password authentication is disabled (`disable_password_authentication = true`)
- **Default VM size**: `Standard_B1s` (cheapest option in West Europe)
- **Default OS**: Ubuntu 22.04 LTS (Jammy)
- **Public IP** is optional and disabled by default
- **SSH command** is provided in outputs for easy connection
- Module outputs include `ssh_command` for quick access

## Security Features

- Password authentication disabled
- SSH key required
- Public IP optional (disabled by default)
- Standard OS disk encryption

## Validation Rules

| Rule | Description |
|------|-------------|
| VM name length | Must be between 1 and 64 characters |
| Admin username | Must be between 1 and 32 characters |
| VM size | Must be a valid Azure VM size |
| Public IP allocation | Must be 'Static' or 'Dynamic' |
| Public IP SKU | Must be 'Basic' or 'Standard' |

<!-- BEGIN_TF_DOCS -->


## Requirements

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.0 |

## Providers

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.0 |

## Resources

## Resources

| Name | Type |
|------|------|
| [azurerm_linux_virtual_machine.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |

## Inputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | Azure region | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group name | `string` | n/a | yes |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | SSH public key for authentication | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID where the VM will be placed | `string` | n/a | yes |
| <a name="input_vm_name"></a> [vm\_name](#input\_vm\_name) | Name of the virtual machine | `string` | n/a | yes |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | Admin username for the VM | `string` | `"azureuser"` | no |
| <a name="input_enable_public_ip"></a> [enable\_public\_ip](#input\_enable\_public\_ip) | Enable public IP for the VM | `bool` | `false` | no |
| <a name="input_image_offer"></a> [image\_offer](#input\_image\_offer) | VM image offer | `string` | `"0001-com-ubuntu-server-jammy"` | no |
| <a name="input_image_publisher"></a> [image\_publisher](#input\_image\_publisher) | VM image publisher | `string` | `"Canonical"` | no |
| <a name="input_image_sku"></a> [image\_sku](#input\_image\_sku) | VM image SKU | `string` | `"22_04-lts-gen2"` | no |
| <a name="input_image_version"></a> [image\_version](#input\_image\_version) | VM image version | `string` | `"latest"` | no |
| <a name="input_os_disk_type"></a> [os\_disk\_type](#input\_os\_disk\_type) | OS disk storage account type | `string` | `"Standard_LRS"` | no |
| <a name="input_public_ip_allocation_method"></a> [public\_ip\_allocation\_method](#input\_public\_ip\_allocation\_method) | Public IP allocation method (Static or Dynamic) | `string` | `"Static"` | no |
| <a name="input_public_ip_sku"></a> [public\_ip\_sku](#input\_public\_ip\_sku) | Public IP SKU (Basic or Standard) | `string` | `"Standard"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | `{}` | no |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | Size of the virtual machine | `string` | `"Standard_B1s"` | no |

## Outputs

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_username"></a> [admin\_username](#output\_admin\_username) | The admin username for the VM |
| <a name="output_network_interface_id"></a> [network\_interface\_id](#output\_network\_interface\_id) | The ID of the network interface |
| <a name="output_private_ip_address"></a> [private\_ip\_address](#output\_private\_ip\_address) | The private IP address of the VM |
| <a name="output_public_ip_address"></a> [public\_ip\_address](#output\_public\_ip\_address) | The public IP address of the VM (null if public IP is disabled) |
| <a name="output_ssh_command"></a> [ssh\_command](#output\_ssh\_command) | SSH command to connect to the VM |
| <a name="output_vm_id"></a> [vm\_id](#output\_vm\_id) | The ID of the virtual machine |
| <a name="output_vm_name"></a> [vm\_name](#output\_vm\_name) | The name of the virtual machine |
<!-- END_TF_DOCS -->
