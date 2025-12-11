# Backend Administration

## Structure

```text
Storage Account: stterraformstate
├── Container: terraform-state-prd
│   ├── project-a/terraform.tfstate
│   └── project-b/terraform.tfstate
├── Container: terraform-state-qlt
└── Container: terraform-state-tst
```

## Operations

### View State

```bash
terraform state list
terraform state show <resource>
terraform state pull > backup.tfstate
```

### Download State File

```bash
az storage blob download \
  --account-name stterraformstate \
  --container-name terraform-state-prd \
  --name "project-a/terraform.tfstate" \
  --file state.json \
  --auth-mode login
```

### Force Unlock

```bash
terraform force-unlock <LOCK_ID>
```

### Move Resources

```bash
terraform state mv <source> <destination>
```

### Remove Resources

```bash
terraform state rm <resource>
```

## Backup and Restore

### Manual Backup

```bash
terraform state pull > backup-$(date +%Y%m%d).tfstate
```

### Restore from Backup

```bash
terraform state push backup-20251211.tfstate
```

### List Versions

```bash
az storage blob list \
  --account-name stterraformstate \
  --container-name terraform-state-prd \
  --prefix "project-a/" \
  --include v \
  --auth-mode login
```

## Troubleshooting

### State Lock

```bash
# Wait 15 seconds (auto-expires)
# Or force unlock
terraform force-unlock <LOCK_ID>
```

### Corrupted State

```bash
# Restore from version
az storage blob download \
  --account-name stterraformstate \
  --container-name terraform-state-prd \
  --name "project-a/terraform.tfstate" \
  --version-id <VERSION> \
  --file restored.tfstate

terraform state push restored.tfstate
```

### Access Denied

```bash
# Check SP permissions
az role assignment list --assignee $ARM_CLIENT_ID
```

## References

- [Setup Guide](SETUP.md)
- [Terraform Project Template](../terraform-project-template/README.md)
