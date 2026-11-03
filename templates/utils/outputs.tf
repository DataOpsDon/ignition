output "name" {
  description = "Standardized names for Azure resources"
  value = {
    resource_group       = "rg-${local.location_short}-${var.project}-${var.lz}-${var.suffix}"
    storage_account      = "st${local.location_short}${var.project}${var.lz}${var.suffix}"
    key_vault            = "kv-${local.location_short}-${var.project}-${var.lz}-${var.suffix}"
    databricks_workspace = "dbw-${local.location_short}-${var.project}-${var.lz}-${var.suffix}"
    data_factory         = "adf-${local.location_short}-${var.project}-${var.lz}-${var.suffix}"
    virtual_network      = "vnet-${local.location_short}-${var.project}-${var.lz}-${var.suffix}"
    sql_server           = "sql-${local.location_short}-${var.project}-${var.lz}-${var.suffix}"
    app_service          = "app-${local.location_short}-${var.project}-${var.lz}-${var.suffix}"
  }
}

output "lz" {
  description = "Landing zone code"
  value       = var.lz
}

output "location_short" {
  description = "Short location code"
  value       = local.location_short
}
