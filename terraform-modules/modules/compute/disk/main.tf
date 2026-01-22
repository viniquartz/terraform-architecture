terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

resource "azurerm_managed_disk" "this" {
  name                             = var.name
  resource_group_name              = var.resource_group_name
  location                         = var.location
  storage_account_type             = var.storage_account_type
  create_option                    = var.create_option
  disk_size_gb                     = var.disk_size_gb
  os_type                          = var.os_type
  source_resource_id               = var.source_resource_id
  source_uri                       = var.source_uri
  storage_account_id               = var.storage_account_id
  image_reference_id               = var.image_reference_id
  gallery_image_reference_id       = var.gallery_image_reference_id
  hyper_v_generation               = var.hyper_v_generation
  on_demand_bursting_enabled       = var.on_demand_bursting_enabled
  trusted_launch_enabled           = var.trusted_launch_enabled
  security_type                    = var.security_type
  secure_vm_disk_encryption_set_id = var.secure_vm_disk_encryption_set_id
  disk_encryption_set_id           = var.disk_encryption_set_id
  disk_iops_read_write             = var.disk_iops_read_write
  disk_mbps_read_write             = var.disk_mbps_read_write
  disk_iops_read_only              = var.disk_iops_read_only
  disk_mbps_read_only              = var.disk_mbps_read_only
  upload_size_bytes                = var.upload_size_bytes
  tier                             = var.tier
  max_shares                       = var.max_shares
  zone                             = var.zone
  network_access_policy            = var.network_access_policy
  disk_access_id                   = var.disk_access_id
  public_network_access_enabled    = var.public_network_access_enabled
  edge_zone                        = var.edge_zone

  dynamic "encryption_settings" {
    for_each = var.encryption_settings != null ? [var.encryption_settings] : []
    content {
      dynamic "disk_encryption_key" {
        for_each = encryption_settings.value.disk_encryption_key != null ? [encryption_settings.value.disk_encryption_key] : []
        content {
          secret_url      = disk_encryption_key.value.secret_url
          source_vault_id = disk_encryption_key.value.source_vault_id
        }
      }

      dynamic "key_encryption_key" {
        for_each = encryption_settings.value.key_encryption_key != null ? [encryption_settings.value.key_encryption_key] : []
        content {
          key_url         = key_encryption_key.value.key_url
          source_vault_id = key_encryption_key.value.source_vault_id
        }
      }
    }
  }

  tags = var.tags
}
