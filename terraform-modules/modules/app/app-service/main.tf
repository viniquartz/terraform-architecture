terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

resource "azurerm_linux_web_app" "this" {
  count = var.os_type == "Linux" ? 1 : 0

  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  service_plan_id               = var.service_plan_id
  https_only                    = var.https_only
  client_affinity_enabled       = var.client_affinity_enabled
  enabled                       = var.enabled
  public_network_access_enabled = var.public_network_access_enabled
  virtual_network_subnet_id     = var.virtual_network_subnet_id

  site_config {
    always_on                               = var.always_on
    ftps_state                              = var.ftps_state
    health_check_path                       = var.health_check_path
    health_check_eviction_time_in_min       = var.health_check_eviction_time_in_min
    http2_enabled                           = var.http2_enabled
    minimum_tls_version                     = var.minimum_tls_version
    remote_debugging_enabled                = var.remote_debugging_enabled
    scm_minimum_tls_version                 = var.scm_minimum_tls_version
    vnet_route_all_enabled                  = var.vnet_route_all_enabled
    websockets_enabled                      = var.websockets_enabled
    container_registry_use_managed_identity = var.container_registry_use_managed_identity

    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        docker_image     = application_stack.value.docker_image
        docker_image_tag = application_stack.value.docker_image_tag
        dotnet_version   = application_stack.value.dotnet_version
        java_version     = application_stack.value.java_version
        node_version     = application_stack.value.node_version
        php_version      = application_stack.value.php_version
        python_version   = application_stack.value.python_version
        ruby_version     = application_stack.value.ruby_version
      }
    }
  }

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  app_settings = var.app_settings

  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  tags = var.tags
}

resource "azurerm_windows_web_app" "this" {
  count = var.os_type == "Windows" ? 1 : 0

  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  service_plan_id               = var.service_plan_id
  https_only                    = var.https_only
  client_affinity_enabled       = var.client_affinity_enabled
  enabled                       = var.enabled
  public_network_access_enabled = var.public_network_access_enabled
  virtual_network_subnet_id     = var.virtual_network_subnet_id

  site_config {
    always_on                               = var.always_on
    ftps_state                              = var.ftps_state
    health_check_path                       = var.health_check_path
    health_check_eviction_time_in_min       = var.health_check_eviction_time_in_min
    http2_enabled                           = var.http2_enabled
    minimum_tls_version                     = var.minimum_tls_version
    remote_debugging_enabled                = var.remote_debugging_enabled
    scm_minimum_tls_version                 = var.scm_minimum_tls_version
    vnet_route_all_enabled                  = var.vnet_route_all_enabled
    websockets_enabled                      = var.websockets_enabled
    container_registry_use_managed_identity = var.container_registry_use_managed_identity

    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []
      content {
        current_stack             = application_stack.value.current_stack
        dotnet_version            = application_stack.value.dotnet_version
        java_version              = application_stack.value.java_version
        node_version              = application_stack.value.node_version
        php_version               = application_stack.value.php_version
        python                    = application_stack.value.python
        docker_container_name     = application_stack.value.docker_container_name
        docker_container_registry = application_stack.value.docker_container_registry
      }
    }
  }

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_type == "UserAssigned" || var.identity_type == "SystemAssigned, UserAssigned" ? var.identity_ids : null
    }
  }

  app_settings = var.app_settings

  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.key
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  tags = var.tags
}
