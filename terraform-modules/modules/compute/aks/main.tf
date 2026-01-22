terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

resource "azurerm_kubernetes_cluster" "this" {
  name                              = var.name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  dns_prefix                        = var.dns_prefix
  kubernetes_version                = var.kubernetes_version
  sku_tier                          = var.sku_tier
  automatic_channel_upgrade         = var.automatic_channel_upgrade
  node_resource_group               = var.node_resource_group
  private_cluster_enabled           = var.private_cluster_enabled
  role_based_access_control_enabled = var.role_based_access_control_enabled

  default_node_pool {
    name                         = var.default_node_pool.name
    vm_size                      = var.default_node_pool.vm_size
    node_count                   = var.default_node_pool.node_count
    enable_auto_scaling          = var.default_node_pool.enable_auto_scaling
    min_count                    = var.default_node_pool.min_count
    max_count                    = var.default_node_pool.max_count
    max_pods                     = var.default_node_pool.max_pods
    os_disk_size_gb              = var.default_node_pool.os_disk_size_gb
    os_disk_type                 = var.default_node_pool.os_disk_type
    vnet_subnet_id               = var.default_node_pool.vnet_subnet_id
    zones                        = var.default_node_pool.zones
    node_labels                  = var.default_node_pool.node_labels
    node_taints                  = var.default_node_pool.node_taints
    only_critical_addons_enabled = var.default_node_pool.only_critical_addons_enabled
  }

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" ? var.identity_ids : null
    }
  }

  network_profile {
    network_plugin    = var.network_profile.network_plugin
    network_policy    = var.network_profile.network_policy
    dns_service_ip    = var.network_profile.dns_service_ip
    service_cidr      = var.network_profile.service_cidr
    load_balancer_sku = var.network_profile.load_balancer_sku
    outbound_type     = var.network_profile.outbound_type
  }

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.azure_ad_rbac != null ? [var.azure_ad_rbac] : []
    content {
      managed                = azure_active_directory_role_based_access_control.value.managed
      azure_rbac_enabled     = azure_active_directory_role_based_access_control.value.azure_rbac_enabled
      admin_group_object_ids = azure_active_directory_role_based_access_control.value.admin_group_object_ids
      tenant_id              = azure_active_directory_role_based_access_control.value.tenant_id
    }
  }

  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider_enabled ? [1] : []
    content {
      secret_rotation_enabled  = var.key_vault_secrets_rotation_enabled
      secret_rotation_interval = var.key_vault_secrets_rotation_interval
    }
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "additional" {
  for_each = var.additional_node_pools

  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  name                  = each.key
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  enable_auto_scaling   = each.value.enable_auto_scaling
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  max_pods              = each.value.max_pods
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = each.value.os_disk_type
  os_type               = each.value.os_type
  vnet_subnet_id        = each.value.vnet_subnet_id
  zones                 = each.value.zones
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints
  mode                  = each.value.mode

  tags = merge(var.tags, each.value.tags)
}
