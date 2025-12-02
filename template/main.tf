resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-rg-${var.environment}"
  location = var.location

  tags = var.tags
}

module "vnet" {
  source = "../terraform-modules/vnet"

  vnet_name           = "${var.prefix}-vnet-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.vnet_address_space

  tags = var.tags
}

module "subnet" {
  source = "../terraform-modules/subnet"

  subnet_name          = "${var.prefix}-subnet-${var.environment}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = module.vnet.vnet_name
  address_prefixes     = var.subnet_address_prefixes
}

module "nsg" {
  source = "../terraform-modules/nsg"

  nsg_name            = "${var.prefix}-nsg-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.subnet.subnet_id

  tags = var.tags
}

module "ssh_rule" {
  source = "../terraform-modules/ssh"

  rule_name                   = "allow-ssh-${var.environment}"
  priority                    = var.ssh_rule_priority
  source_address_prefix       = var.ssh_source_address_prefix
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = module.nsg.nsg_name
}

module "vm" {
  source = "../terraform-modules/vm-linux"

  vm_name             = "${var.prefix}-vm-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  ssh_public_key      = var.ssh_public_key
  subnet_id           = module.subnet.subnet_id
  enable_public_ip    = var.enable_public_ip
  os_disk_type        = var.os_disk_type

  tags = var.tags
}
