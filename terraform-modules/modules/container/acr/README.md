# Azure Container Registry Module

Terraform module to create and manage Azure Container Registry.

## Features

- Multiple SKU support (Basic, Standard, Premium)
- Admin user option
- Geo-replication (Premium SKU)
- Content trust and image quarantine
- Webhook support
- Network rules configuration

## Usage

### Basic Example (POC)

```hcl
module "acr" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/container/acr?ref=v1.0.0"
  
  name                = module.naming.container_registry
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = "Basic"
  
  tags = local.common_tags
}
```

### Standard with Admin User

```hcl
module "acr" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/container/acr?ref=v1.0.0"
  
  name                = module.naming.container_registry
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = true
  
  tags = local.common_tags
}
```

### Premium with Geo-Replication

```hcl
module "acr" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/container/acr?ref=v1.0.0"
  
  name                = module.naming.container_registry
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = "Premium"
  
  georeplications = [
    {
      location = "westeurope"
      tags     = {}
    },
    {
      location = "eastus"
      tags     = {}
    }
  ]
  
  tags = local.common_tags
}
```

### Production with Security Features

```hcl
module "acr_production" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/container/acr?ref=v1.0.0"
  
  name                = module.naming.container_registry
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = "Premium"
  
  # Security
  admin_enabled              = false
  public_network_access_enabled = false
  
  # Network rules
  network_rule_set = {
    default_action = "Deny"
    ip_rules = [
      {
        ip_range = "203.0.113.0/24"
      }
    ]
    virtual_network_rules = [
      {
        subnet_id = module.vnet.subnet_ids["private"]
      }
    ]
  }
  
  # Content trust
  trust_policy_enabled = true
  
  # Image quarantine
  quarantine_policy_enabled = true
  
  # Retention policy
  retention_policy = {
    days    = 30
    enabled = true
  }
  
  tags = local.common_tags
}
```

### With AKS Integration

```hcl
module "acr" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/container/acr?ref=v1.0.0"
  
  name                = module.naming.container_registry
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = "Standard"
  
  tags = local.common_tags
}

# Grant AKS access to ACR
resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = module.acr.id
  skip_service_principal_aad_check = true
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Container Registry name | string | - | yes |
| resource_group_name | Resource Group name | string | - | yes |
| location | Azure region | string | - | yes |
| sku | SKU (Basic, Standard, Premium) | string | - | yes |
| admin_enabled | Enable admin user | bool | false | no |
| public_network_access_enabled | Enable public network access | bool | true | no |
| georeplications | List of geo-replication locations | list(object) | [] | no |
| network_rule_set | Network rule configuration | object | null | no |
| trust_policy_enabled | Enable content trust | bool | false | no |
| quarantine_policy_enabled | Enable quarantine policy | bool | false | no |
| retention_policy | Retention policy configuration | object | null | no |
| tags | Tags to apply to resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Container Registry ID |
| name | Container Registry name |
| login_server | Login server URL |
| admin_username | Admin username (if enabled) |
| admin_password | Admin password (sensitive, if enabled) |

## SKU Comparison

| Feature | Basic | Standard | Premium |
|---------|-------|----------|---------|
| Storage | 10 GB | 100 GB | 500 GB |
| Webhooks | 2 | 10 | 500 |
| Geo-replication | No | No | Yes |
| Content trust | No | No | Yes |
| Private Link | No | No | Yes |
| Image quarantine | No | No | Yes |
| Best for | Dev/Test | Production | Enterprise |

## Login to ACR

### Using Azure CLI

```bash
# Login with Azure AD
az acr login --name <registry-name>

# Login with admin credentials
docker login <registry-name>.azurecr.io -u <admin-username> -p <admin-password>
```

### Using Service Principal

```bash
# Create service principal
az ad sp create-for-rbac \
  --name acr-service-principal \
  --role acrpull \
  --scopes /subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.ContainerRegistry/registries/<acr-name>

# Login
docker login <registry-name>.azurecr.io \
  -u <sp-client-id> \
  -p <sp-client-secret>
```

## Push/Pull Images

```bash
# Tag image
docker tag myapp:latest <registry-name>.azurecr.io/myapp:v1.0.0

# Push image
docker push <registry-name>.azurecr.io/myapp:v1.0.0

# Pull image
docker pull <registry-name>.azurecr.io/myapp:v1.0.0

# List images
az acr repository list --name <registry-name> --output table

# Show tags
az acr repository show-tags --name <registry-name> --repository myapp
```

## Image Scanning (Premium)

```bash
# Enable Microsoft Defender for Containers
az security pricing create \
  --name ContainerRegistry \
  --tier Standard

# View scan results
az security assessment list \
  --query "[?properties.resourceDetails.Id contains 'Microsoft.ContainerRegistry'].{Name:name, Status:properties.status.code}"
```

## Webhooks

```hcl
resource "azurerm_container_registry_webhook" "main" {
  name                = "webhook-ci"
  resource_group_name = azurerm_resource_group.main.name
  registry_name       = module.acr.name
  location            = var.location
  
  service_uri = "https://myapp.example.com/webhook"
  status      = "enabled"
  scope       = "myapp:*"
  actions     = ["push", "delete"]
  
  custom_headers = {
    "Content-Type" = "application/json"
  }
}
```

## Security Best Practices

### For POC/Development
- Use Basic or Standard SKU (cost-effective)
- Admin user enabled (simpler authentication)
- Public network access enabled
- No geo-replication

Example:

```hcl
module "acr_dev" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/container/acr?ref=v1.0.0"
  
  name                = module.naming.container_registry
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
  
  tags = local.common_tags
}
```

### For Production
- Use Premium SKU (advanced features)
- Disable admin user (use Azure AD or service principals)
- Disable public network access
- Enable Private Link
- Configure network rules
- Enable content trust
- Enable geo-replication
- Implement retention policies

Example:

```hcl
module "acr_prod" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/container/acr?ref=v1.0.0"
  
  name                          = module.naming.container_registry
  resource_group_name           = azurerm_resource_group.main.name
  location                      = var.location
  sku                           = "Premium"
  admin_enabled                 = false
  public_network_access_enabled = false
  
  network_rule_set = {
    default_action = "Deny"
    ip_rules       = []
    virtual_network_rules = [
      {
        subnet_id = module.vnet.subnet_ids["private"]
      }
    ]
  }
  
  trust_policy_enabled      = true
  quarantine_policy_enabled = true
  
  retention_policy = {
    days    = 90
    enabled = true
  }
  
  georeplications = [
    {
      location = "westeurope"
      tags     = {}
    }
  ]
  
  tags = local.common_tags
}
```

## Naming Convention

ACR names must be:
- Globally unique
- 5-50 characters
- Alphanumeric only (no hyphens or underscores)
- Lowercase

Example: `azrprddatalake01brsacr`

## Cost Optimization

### Basic SKU
- Storage: 10 GB included
- Additional storage: ~$0.10/GB/month
- Best for: Small projects, dev/test

### Standard SKU
- Storage: 100 GB included
- Additional storage: ~$0.10/GB/month
- Best for: Production workloads

### Premium SKU
- Storage: 500 GB included
- Additional storage: ~$0.10/GB/month
- Geo-replication: Additional cost per location
- Best for: Enterprise, multi-region

### Tips
- Clean up old images regularly
- Use retention policies to auto-delete
- Monitor storage usage
- Consider Standard SKU for most production workloads

## Notes

- ACR names are globally unique across Azure
- Admin user provides 2 passwords (rotate regularly)
- Content trust requires Premium SKU
- Geo-replication requires Premium SKU
- Private Link requires Premium SKU

## Common Issues

### Issue: Registry name not available

**Error:** `The registry <name> is not available`

**Solution:** Choose different name (globally unique required)

### Issue: Cannot push image

**Error:** `unauthorized: authentication required`

**Solution:**
1. Login: `az acr login --name <registry-name>`
2. Verify credentials
3. Check RBAC permissions

### Issue: Image pull failed in AKS

**Error:** `Failed to pull image: unauthorized`

**Solution:**
1. Grant AKS AcrPull role
2. Verify service principal permissions
3. Check network connectivity

### Issue: Quota exceeded

**Error:** `Storage quota exceeded`

**Solution:**
1. Clean up old images
2. Enable retention policy
3. Upgrade SKU if needed

## Migration from Old Structure

Old path: `modules/acr`
New path: `modules/container/acr`

Update your module sources:

```hcl
# Old
module "acr" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/acr?ref=v1.0.0"
}

# New
module "acr" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/container/acr?ref=v2.0.0"
}
```
