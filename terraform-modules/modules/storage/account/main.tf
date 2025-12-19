terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

resource "azurerm_storage_account" "main" {
  name                      = var.name
  resource_group_name       = var.resource_group_name
  location                  = var.location
  account_tier              = var.account_tier
  account_replication_type  = var.account_replication_type
  account_kind              = var.account_kind
  access_tier               = var.access_tier
  
  # Security settings
  min_tls_version                 = var.min_tls_version
  https_traffic_only_enabled      = var.enable_https_traffic_only
  public_network_access_enabled   = var.public_network_access_enabled
  infrastructure_encryption_enabled = var.enable_infrastructure_encryption
  
  # Blob properties
  dynamic "blob_properties" {
    for_each = var.blob_properties != null ? [var.blob_properties] : []
    
    content {
      versioning_enabled       = blob_properties.value.versioning_enabled
      change_feed_enabled      = blob_properties.value.change_feed_enabled
      last_access_time_enabled = blob_properties.value.last_access_time_enabled
      
      delete_retention_policy {
        days = blob_properties.value.delete_retention_days
      }
      
      container_delete_retention_policy {
        days = blob_properties.value.container_delete_retention_days
      }
    }
  }
  
  # Network rules
  dynamic "network_rules" {
    for_each = var.network_rules != null ? [var.network_rules] : []
    
    content {
      default_action             = network_rules.value.default_action
      bypass                     = network_rules.value.bypass
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
    }
  }
  
  tags = var.tags
}

# Advanced Threat Protection
resource "azurerm_advanced_threat_protection" "main" {
  count              = var.enable_advanced_threat_protection ? 1 : 0
  target_resource_id = azurerm_storage_account.main.id
  enabled            = true
}

# Blob containers
resource "azurerm_storage_container" "containers" {
  for_each = var.containers
  
  name                  = each.key
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = each.value.access_type
}

# File shares
resource "azurerm_storage_share" "shares" {
  for_each = var.shares
  
  name                 = each.key
  storage_account_name = azurerm_storage_account.main.name
  quota                = each.value.quota
}

# Queues
resource "azurerm_storage_queue" "queues" {
  for_each = toset(var.queues)
  
  name                 = each.value
  storage_account_name = azurerm_storage_account.main.name
}

# Tables
resource "azurerm_storage_table" "tables" {
  for_each = toset(var.tables)
  
  name                 = each.value
  storage_account_name = azurerm_storage_account.main.name
}

