# AKS (Azure Kubernetes Service) Module

Terraform module to create Azure Kubernetes Service clusters.

## Features

- System and User node pools
- Auto-scaling
- Azure CNI and Kubenet networking
- Private clusters
- Azure AD integration
- Key Vault Secrets Provider
- Azure Monitor integration
- Zone redundancy
- Multiple node pools

## Usage

### Basic AKS Cluster

```hcl
module "aks" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/aks?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-aks"
  resource_group_name = module.rg.name
  location            = var.location
  dns_prefix          = "myapp"
  
  default_node_pool = {
    name       = "default"
    vm_size    = "Standard_D2s_v3"
    node_count = 3
  }
  
  identity_type = "SystemAssigned"
  
  tags = local.common_tags
}
```

### Production AKS with Auto-scaling

```hcl
module "aks_prod" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/aks?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-aks-prod"
  resource_group_name = module.rg.name
  location            = "westeurope"
  dns_prefix          = "myapp-prod"
  kubernetes_version  = "1.28"
  sku_tier            = "Standard"
  
  default_node_pool = {
    name                = "system"
    vm_size             = "Standard_D4s_v3"
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 10
    zones               = ["1", "2", "3"]
    vnet_subnet_id      = module.subnet_aks.id
    only_critical_addons_enabled = true
  }
  
  network_profile = {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"
  }
  
  identity_type = "SystemAssigned"
  
  tags = local.common_tags
}
```

### With Additional Node Pools

```hcl
module "aks_multi_pool" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/aks?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-aks"
  resource_group_name = module.rg.name
  location            = "westeurope"
  dns_prefix          = "myapp"
  
  default_node_pool = {
    name       = "system"
    vm_size    = "Standard_D2s_v3"
    node_count = 3
    node_labels = {
      role = "system"
    }
  }
  
  additional_node_pools = {
    workload = {
      vm_size             = "Standard_D4s_v3"
      enable_auto_scaling = true
      min_count           = 2
      max_count           = 10
      node_labels = {
        role = "workload"
      }
    }
    gpu = {
      vm_size    = "Standard_NC6s_v3"
      node_count = 2
      node_taints = ["gpu=true:NoSchedule"]
      node_labels = {
        accelerator = "nvidia"
      }
    }
  }
  
  tags = local.common_tags
}
```

### Private AKS with Azure AD

```hcl
module "aks_private" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/aks?ref=v1.0.0"
  
  name                    = "${module.naming.base_name}-aks-private"
  resource_group_name     = module.rg.name
  location                = "westeurope"
  dns_prefix              = "myapp-private"
  private_cluster_enabled = true
  
  default_node_pool = {
    name           = "system"
    vm_size        = "Standard_D2s_v3"
    node_count     = 3
    vnet_subnet_id = module.subnet_aks.id
  }
  
  network_profile = {
    network_plugin = "azure"
    network_policy = "calico"
    service_cidr   = "10.1.0.0/16"
    dns_service_ip = "10.1.0.10"
  }
  
  azure_ad_rbac = {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = [var.aks_admin_group_id]
  }
  
  identity_type = "SystemAssigned"
  
  tags = local.common_tags
}
```

### With Key Vault Secrets Provider

```hcl
module "aks_keyvault" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/aks?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-aks"
  resource_group_name = module.rg.name
  location            = "westeurope"
  dns_prefix          = "myapp"
  
  default_node_pool = {
    name       = "system"
    vm_size    = "Standard_D2s_v3"
    node_count = 3
  }
  
  key_vault_secrets_provider_enabled  = true
  key_vault_secrets_rotation_enabled  = true
  key_vault_secrets_rotation_interval = "2m"
  
  identity_type = "SystemAssigned"
  
  tags = local.common_tags
}
```

### With Azure Monitor

```hcl
module "aks_monitored" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/aks?ref=v1.0.0"
  
  name                = "${module.naming.base_name}-aks"
  resource_group_name = module.rg.name
  location            = "westeurope"
  dns_prefix          = "myapp"
  
  default_node_pool = {
    name       = "system"
    vm_size    = "Standard_D2s_v3"
    node_count = 3
  }
  
  log_analytics_workspace_id = module.log_analytics.id
  
  identity_type = "SystemAssigned"
  
  tags = local.common_tags
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| name | AKS name | string | Yes | - |
| resource_group_name | Resource Group | string | Yes | - |
| location | Azure region | string | Yes | - |
| dns_prefix | DNS prefix | string | Yes | - |
| kubernetes_version | K8s version | string | No | null |
| sku_tier | SKU tier | string | No | Free |
| default_node_pool | Node pool config | object | Yes | - |
| network_profile | Network config | object | No | azure plugin |
| private_cluster_enabled | Private cluster | bool | No | false |
| azure_ad_rbac | Azure AD config | object | No | null |
| additional_node_pools | Extra pools | map | No | {} |
| tags | Tags | map(string) | No | {} |

## Outputs

| Name | Description |
|------|-------------|
| id | AKS cluster ID |
| name | AKS cluster name |
| fqdn | FQDN |
| kube_config_raw | Raw kubeconfig (sensitive) |
| identity_principal_id | Managed Identity ID |
| kubelet_identity | Kubelet identity |

## Network Plugins

### Azure CNI

- Advanced networking
- Pods get IPs from VNet
- Better performance
- More IP addresses required

```hcl
network_profile = {
  network_plugin = "azure"
  network_policy = "azure"
  service_cidr   = "10.1.0.0/16"
  dns_service_ip = "10.1.0.10"
}
```

### Kubenet

- Basic networking
- Pods use overlay network
- Less IP addresses
- Lower performance

```hcl
network_profile = {
  network_plugin = "kubenet"
  service_cidr   = "10.1.0.0/16"
  dns_service_ip = "10.1.0.10"
}
```

## SKU Tiers

| Tier | SLA | Use Case |
|------|-----|----------|
| Free | None | Development/testing |
| Standard | 99.9% uptime | Production workloads |
| Premium | 99.95% with zones | Mission-critical |

## VM Sizes for Node Pools

| Size | vCPUs | RAM | Use Case |
|------|-------|-----|----------|
| Standard_D2s_v3 | 2 | 8 GB | Small workloads |
| Standard_D4s_v3 | 4 | 16 GB | Standard workloads |
| Standard_D8s_v3 | 8 | 32 GB | Large workloads |
| Standard_E4s_v3 | 4 | 32 GB | Memory-intensive |
| Standard_NC6s_v3 | 6 | 112 GB | GPU workloads |

## Subnet Requirements

The AKS subnet requires:

- Sufficient IP addresses (Azure CNI: /24 or larger)
- Service endpoint for `Microsoft.ContainerRegistry` (optional)
- No delegation

```hcl
module "subnet_aks" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/network/subnet?ref=v1.0.0"
  
  name                 = "${module.naming.subnet}-aks"
  resource_group_name  = module.rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.10.0/22"]  # /22 for Azure CNI
  
  service_endpoints = ["Microsoft.ContainerRegistry"]
}
```

## Complete Production Example

```hcl
module "aks_production" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/compute/aks?ref=v1.0.0"
  
  name                      = "${module.naming.base_name}-aks-prod"
  resource_group_name       = module.rg.name
  location                  = "westeurope"
  dns_prefix                = "myapp-prod"
  kubernetes_version        = "1.28"
  sku_tier                  = "Standard"
  automatic_channel_upgrade = "stable"
  private_cluster_enabled   = true
  
  default_node_pool = {
    name                         = "system"
    vm_size                      = "Standard_D4s_v3"
    enable_auto_scaling          = true
    min_count                    = 3
    max_count                    = 10
    zones                        = ["1", "2", "3"]
    vnet_subnet_id               = module.subnet_aks.id
    only_critical_addons_enabled = true
    os_disk_size_gb              = 128
  }
  
  additional_node_pools = {
    workload = {
      vm_size             = "Standard_D8s_v3"
      enable_auto_scaling = true
      min_count           = 2
      max_count           = 20
      zones               = ["1", "2", "3"]
      vnet_subnet_id      = module.subnet_aks.id
      node_labels = {
        workload = "general"
      }
    }
  }
  
  network_profile = {
    network_plugin    = "azure"
    network_policy    = "azure"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }
  
  azure_ad_rbac = {
    managed                = true
    azure_rbac_enabled     = true
    admin_group_object_ids = [var.aks_admin_group_id]
  }
  
  key_vault_secrets_provider_enabled  = true
  key_vault_secrets_rotation_enabled  = true
  log_analytics_workspace_id           = module.log_analytics.id
  
  identity_type = "SystemAssigned"
  
  tags = merge(local.common_tags, {
    Tier = "Production"
  })
}
```
