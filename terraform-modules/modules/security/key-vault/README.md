# Key Vault Module

Terraform module to create and manage Azure Key Vault.

## Features

- Standard or Premium SKU
- Azure RBAC or Access Policies
- Network ACLs support
- Soft delete with configurable retention
- Purge protection
- VM, disk encryption, and template deployment integration

## Usage

### Basic Key Vault (RBAC)

```hcl
data "azurerm_client_config" "current" {}

module "key_vault" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/security/key-vault?ref=v1.0.0"
  
  name                = module.naming.key_vault
  resource_group_name = module.rg.name
  location            = var.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  enable_rbac_authorization = true
  purge_protection_enabled  = true
  
  tags = local.common_tags
}
```

### With Network Restrictions

```hcl
module "key_vault_secure" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/security/key-vault?ref=v1.0.0"
  
  name                = module.naming.key_vault
  resource_group_name = module.rg.name
  location            = "westeurope"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  public_network_access_enabled = false
  
  network_acls = {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = ["203.0.113.0/24"]
    virtual_network_subnet_ids = [module.subnet_app.id]
  }
  
  tags = local.common_tags
}
```

### With Access Policies (Legacy)

```hcl
data "azurerm_client_config" "current" {}

module "key_vault_policies" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/security/key-vault?ref=v1.0.0"
  
  name                = module.naming.key_vault
  resource_group_name = module.rg.name
  location            = "westeurope"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  enable_rbac_authorization = false
  
  access_policies = {
    admin = {
      object_id = data.azurerm_client_config.current.object_id
      key_permissions = [
        "Get", "List", "Create", "Delete", "Update", "Import"
      ]
      secret_permissions = [
        "Get", "List", "Set", "Delete"
      ]
      certificate_permissions = [
        "Get", "List", "Create", "Delete", "Update", "Import"
      ]
      storage_permissions = []
    }
  }
  
  tags = local.common_tags
}
```

### For VM Deployment

```hcl
module "key_vault_vm" {
  source = "git@github.com:org/terraform-azure-modules.git//modules/security/key-vault?ref=v1.0.0"
  
  name                = module.naming.key_vault
  resource_group_name = module.rg.name
  location            = "westeurope"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  
  tags = local.common_tags
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| name | Key Vault name (3-24 chars) | string | Yes | - |
| resource_group_name | Resource Group name | string | Yes | - |
| location | Azure region | string | Yes | - |
| tenant_id | Azure AD Tenant ID | string | Yes | - |
| sku_name | standard or premium | string | No | standard |
| enable_rbac_authorization | Use RBAC instead of policies | bool | No | true |
| purge_protection_enabled | Enable purge protection | bool | No | true |
| soft_delete_retention_days | Retention days (7-90) | number | No | 90 |
| public_network_access_enabled | Enable public access | bool | No | true |
| network_acls | Network ACLs config | object | No | null |
| access_policies | Access policies map | map(object) | No | {} |
| tags | Tags to apply | map(string) | No | {} |

## Outputs

| Name | Description |
|------|-------------|
| id | Key Vault ID |
| name | Key Vault name |
| vault_uri | Key Vault URI |
| tenant_id | Tenant ID |

## RBAC Roles

When using `enable_rbac_authorization = true`, assign roles:

```bash
# Key Vault Administrator
az role assignment create \
  --role "Key Vault Administrator" \
  --assignee user@example.com \
  --scope /subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/...

# Key Vault Secrets User (for applications)
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee <managed-identity-id> \
  --scope /subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/...
```

## Premium SKU Features

- HSM-backed keys
- Bring your own key (BYOK)
- Enhanced security compliance

## Best Practices

1. **Use RBAC** (`enable_rbac_authorization = true`) for new deployments
2. **Enable purge protection** in production
3. **Restrict network access** with `network_acls`
4. **Use Private Endpoints** for production workloads
5. **Monitor access** with Azure Monitor
6. **Soft delete retention**: 90 days for production
