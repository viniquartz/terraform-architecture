variable "name" {
  description = "SQL Database name"
  type        = string
}

variable "server_id" {
  description = "SQL Server ID"
  type        = string
}

variable "collation" {
  description = "Database collation"
  type        = string
  default     = "SQL_Latin1_General_CP1_CI_AS"
}

variable "license_type" {
  description = "License type (LicenseIncluded or BasePrice)"
  type        = string
  default     = null
}

variable "max_size_gb" {
  description = "Maximum size in GB"
  type        = number
  default     = null
}

variable "read_scale" {
  description = "Enable read scale-out (Enabled or Disabled)"
  type        = bool
  default     = false
}

variable "sku_name" {
  description = "SKU name (Basic, S0-S12, P1-P15, GP_Gen5_2, BC_Gen5_2, HS_Gen5_2)"
  type        = string
  default     = "GP_Gen5_2"
}

variable "zone_redundant" {
  description = "Enable zone redundancy"
  type        = bool
  default     = false
}

variable "auto_pause_delay_in_minutes" {
  description = "Auto-pause delay for Serverless (60-10080, -1 to disable)"
  type        = number
  default     = null
}

variable "min_capacity" {
  description = "Minimum vCores for Serverless"
  type        = number
  default     = null
}

variable "read_replica_count" {
  description = "Number of read replicas for Hyperscale"
  type        = number
  default     = null
}

variable "create_mode" {
  description = "Creation mode (Default, Copy, OnlineSecondary, PointInTimeRestore, Recovery, Restore, RestoreExternalBackup, RestoreLongTermRetentionBackup, Secondary)"
  type        = string
  default     = "Default"
}

variable "creation_source_database_id" {
  description = "Source database ID for Copy/Secondary/PointInTimeRestore"
  type        = string
  default     = null
}

variable "restore_point_in_time" {
  description = "Restore point timestamp (ISO 8601)"
  type        = string
  default     = null
}

variable "recover_database_id" {
  description = "Database ID to recover"
  type        = string
  default     = null
}

variable "restore_dropped_database_id" {
  description = "Dropped database ID to restore"
  type        = string
  default     = null
}

variable "geo_backup_enabled" {
  description = "Enable geo-redundant backups"
  type        = bool
  default     = true
}

variable "maintenance_configuration_name" {
  description = "Maintenance window configuration"
  type        = string
  default     = null
}

variable "ledger_enabled" {
  description = "Enable ledger"
  type        = bool
  default     = false
}

variable "transparent_data_encryption_enabled" {
  description = "Enable TDE"
  type        = bool
  default     = true
}

variable "transparent_data_encryption_key_vault_key_id" {
  description = "Key Vault key ID for TDE"
  type        = string
  default     = null
}

variable "transparent_data_encryption_key_automatic_rotation_enabled" {
  description = "Enable automatic TDE key rotation"
  type        = bool
  default     = false
}

variable "storage_account_type" {
  description = "Backup storage redundancy (Geo, Local, Zone, GeoZone)"
  type        = string
  default     = "Geo"
}

variable "secondary_type" {
  description = "Secondary type for Hyperscale (Geo or Named)"
  type        = string
  default     = null
}

variable "elastic_pool_id" {
  description = "Elastic Pool ID"
  type        = string
  default     = null
}

variable "threat_detection_policy" {
  description = "Advanced Threat Protection policy"
  type = object({
    state                      = string
    disabled_alerts            = optional(list(string))
    email_account_admins       = optional(string)
    email_addresses            = optional(list(string))
    retention_days             = optional(number)
    storage_account_access_key = optional(string)
    storage_endpoint           = optional(string)
  })
  default = null
}

variable "long_term_retention_policy" {
  description = "Long-term retention policy"
  type = object({
    weekly_retention  = optional(string)
    monthly_retention = optional(string)
    yearly_retention  = optional(string)
    week_of_year      = optional(number)
  })
  default = null
}

variable "short_term_retention_policy" {
  description = "Short-term retention policy"
  type = object({
    retention_days           = number
    backup_interval_in_hours = optional(number)
  })
  default = null
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
