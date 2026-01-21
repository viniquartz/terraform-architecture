terraform {
  required_version = ">= 1.5.0"
}

# Generate resource names
locals {
  # Standard format: azr-<env>-<project><version>-<region>-<type>[-purpose]
  resource_name = {
    for key, abbr in local.resource_abbreviations :
    key => "${local.base_name}-${abbr}"
  }

  # Special cases for Azure naming restrictions

  # Storage Account: no hyphens/underscores, lowercase only, max 24 chars
  storage_account_name = lower(replace(
    "azr${var.environment}${var.project_name}${var.project_version}${local.region_abbr}st${var.suffix}${var.purpose}",
    "-", ""
  ))

  # Key Vault: hyphens allowed, max 24 chars
  key_vault_name = lower(
    var.purpose != "" ? "azr-${var.environment}-${var.project_name}${var.project_version}-${local.region_abbr}-kv${var.suffix != "" ? "-${var.suffix}" : ""}-${var.purpose}" : "azr-${var.environment}-${var.project_name}${var.project_version}-${local.region_abbr}-kv${var.suffix != "" ? "-${var.suffix}" : ""}"
  )

  # Container Registry: alphanumeric only, max 50 chars
  container_registry_name = lower(replace(
    "azr${var.environment}${var.project_name}${var.project_version}${local.region_abbr}acr${var.suffix}${var.purpose}",
    "-", ""
  ))
}
