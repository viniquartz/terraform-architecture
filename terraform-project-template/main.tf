# ==============================================================================
# NAMING CONVENTION
# ==============================================================================
module "naming" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/foundation/naming?ref=v1.0.0"

  environment     = var.environment
  project_name    = var.project_name
  project_version = "01"
  location        = var.location
  # purpose       = ""  # Optional: web, api, db, etc.
}

# ==============================================================================
# RESOURCE GROUP
# ==============================================================================
resource "azurerm_resource_group" "main" {
  name     = module.naming.resource_group
  location = var.location
  tags     = local.common_tags
}

# ==============================================================================
# NETWORKING - VIRTUAL NETWORK
# ==============================================================================
module "vnet" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/vnet?ref=v1.0.0"

  name                = module.naming.virtual_network
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  address_space       = ["10.0.0.0/16"]

  tags = local.common_tags
}

# ==============================================================================
# NETWORKING - SUBNETS
# ==============================================================================
# Pattern: azr-<env>-<project><version>-<region>-snet-app
module "subnet_app" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/subnet?ref=v1.0.0"

  name                 = "${module.naming.subnet}-app"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Pattern: azr-<env>-<project><version>-<region>-snet-data
module "subnet_data" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/subnet?ref=v1.0.0"

  name                 = "${module.naming.subnet}-data"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# ==============================================================================
# NETWORKING - NETWORK SECURITY GROUP
# ==============================================================================
module "nsg" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/nsg?ref=v1.0.0"

  name                = module.naming.network_security_group
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  tags = local.common_tags
}

# ==============================================================================
# NETWORKING - NSG RULES
# ==============================================================================
module "nsg_rule_ssh" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/nsg-rule?ref=v1.0.0"

  name                        = "allow-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = module.nsg.name
}

module "nsg_rule_rdp" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/nsg-rule?ref=v1.0.0"

  name                        = "allow-rdp"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = module.nsg.name
}

# ==============================================================================
# NETWORKING - NSG SUBNET ASSOCIATION
# ==============================================================================
resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = module.subnet_app.id
  network_security_group_id = module.nsg.id
}

# ==============================================================================
# COMPUTE - LINUX VIRTUAL MACHINE
# ==============================================================================
# Pattern: azr-<env>-<project><version>-<region>-vm-linux
module "vm_linux" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/vm-linux?ref=v1.0.0"

  name                = "${module.naming.virtual_machine}-linux"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  vm_size             = "Standard_B2s"
  subnet_id           = module.subnet_app.id

  admin_username = "azureuser"
  admin_ssh_key  = var.admin_ssh_key_linux

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

  tags = local.common_tags
}

# ==============================================================================
# COMPUTE - WINDOWS VIRTUAL MACHINE
# ==============================================================================
# Pattern: azr-<env>-<project><version>-<region>-vm-windows
module "vm_windows" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/vm-windows?ref=v1.0.0"

  name                = "${module.naming.virtual_machine}-windows"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  vm_size             = "Standard_B2s"
  subnet_id           = module.subnet_app.id

  admin_username = "azureadmin"
  admin_password = var.admin_password_windows

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

  tags = local.common_tags
}

# ==============================================================================
# STORAGE - STORAGE ACCOUNT
# ==============================================================================
module "storage" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/storage/account?ref=v1.0.0"

  name                     = module.naming.storage_account
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  containers = {
    data = {
      access_type = "private"
    }
    logs = {
      access_type = "private"
    }
  }

  tags = local.common_tags
}
