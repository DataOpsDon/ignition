locals {
  location_short_map = {
    "uksouth" = "uks"
    "ukwest"  = "ukw"
    "eastus"  = "eus"
    "westus"  = "wus"
  }

  location_short = lookup(local.location_short_map, var.location, "uks")
}
