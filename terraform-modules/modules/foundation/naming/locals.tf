locals {
  # Region abbreviations based on Azure regions
  # Reference: https://azure.microsoft.com/en-us/explore/global-infrastructure/geographies/
  region_abbreviations = {
    # Europe
    "westeurope"         = "weu"
    "northeurope"        = "neu"
    "francecentral"      = "frc"
    "francesouth"        = "frs"
    "germanywestcentral" = "gwc"
    "germanynorth"       = "gno"
    "norwayeast"         = "noe"
    "norwaywest"         = "now"
    "swedencentral"      = "swc"
    "switzerlandnorth"   = "swn"
    "switzerlandwest"    = "sww"
    "uksouth"            = "uks"
    "ukwest"             = "ukw"
    "italynorth"         = "itn"
    "polandcentral"      = "plc"
    "spaincentral"       = "spc"

    # Americas
    "eastus"          = "eus"
    "eastus2"         = "eu2"
    "westus"          = "wus"
    "westus2"         = "wu2"
    "westus3"         = "wu3"
    "centralus"       = "cus"
    "southcentralus"  = "scu"
    "northcentralus"  = "ncu"
    "westcentralus"   = "wcu"
    "brazilsouth"     = "brs"
    "brazilsoutheast" = "bse"
    "canadacentral"   = "cac"
    "canadaeast"      = "cae"
    "mexicocentral"   = "mxc"
    "chilecentral"    = "clc"

    # Asia Pacific
    "southeastasia"      = "sea"
    "eastasia"           = "eas"
    "australiaeast"      = "aue"
    "australiasoutheast" = "aus"
    "australiacentral"   = "auc"
    "australiacentral2"  = "ac2"
    "japaneast"          = "jpe"
    "japanwest"          = "jpw"
    "koreacentral"       = "krc"
    "koreasouth"         = "krs"
    "centralindia"       = "inc"
    "southindia"         = "ins"
    "westindia"          = "inw"
    "jioindiawest"       = "jiw"
    "jioindiacentral"    = "jic"

    # Middle East & Africa
    "uaenorth"         = "uan"
    "uaecentral"       = "uac"
    "southafricanorth" = "san"
    "southafricawest"  = "saw"
    "qatarcentral"     = "qac"
    "israelcentral"    = "ilc"

    # China (Requires special Azure China account)
    "chinanorth"  = "cnn"
    "chinaeast"   = "cne"
    "chinanorth2" = "cn2"
    "chinaeast2"  = "ce2"
    "chinanorth3" = "cn3"

    # Government Cloud (Requires Azure Government account)
    "usgovvirginia" = "ugv"
    "usgoviowa"     = "ugi"
    "usgovarizona"  = "uga"
    "usgovtexas"    = "ugt"
    "usdodeast"     = "ude"
    "usdodcentral"  = "udc"
  }

  # Resource type abbreviations (Azure CAF standard)
  resource_abbreviations = {
    "virtual_machine"         = "vm"
    "virtual_network"         = "vnet"
    "subnet"                  = "snet"
    "network_security_group"  = "nsg"
    "network_interface"       = "nic"
    "public_ip"               = "pip"
    "load_balancer"           = "lb"
    "storage_account"         = "st"
    "key_vault"               = "kv"
    "app_service"             = "app"
    "function_app"            = "func"
    "sql_database"            = "sqldb"
    "sql_server"              = "sql"
    "cosmos_db"               = "cosmos"
    "redis_cache"             = "redis"
    "event_hub"               = "evh"
    "service_bus"             = "sb"
    "container_registry"      = "acr"
    "kubernetes_cluster"      = "aks"
    "resource_group"          = "rg"
    "application_insights"    = "appi"
    "log_analytics_workspace" = "log"
    "disk"                    = "disk"
  }

  # Get region abbreviation
  region_abbr = lookup(
    local.region_abbreviations,
    var.location,
    substr(replace(var.location, "/[^a-z]/", ""), 0, 3)
  )

  # Base naming pattern: azr-<env>-<project><version>-<region>
  base_name_core = "azr-${var.environment}-${var.project_name}${var.project_version}-${local.region_abbr}"

  # Base naming pattern with optional suffix
  base_name_with_suffix = var.suffix != "" ? "${local.base_name_core}-${var.suffix}" : local.base_name_core

  # Base naming pattern with optional purpose
  base_name = var.purpose != "" ? "${local.base_name_with_suffix}-${var.purpose}" : local.base_name_with_suffix
}
