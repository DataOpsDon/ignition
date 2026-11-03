// ---------------------------------------------------------------------------------------------------------------------
// {stack_name_upper} Stack - {description}
// This Terraform configuration provisions resources for the {stack_name} deployment.
//
// Notes:
// - Naming is centralised via the `naming` module to ensure consistent resource names across environments.

// Module: naming
// Purpose: Centralised naming standards for resources (location, project, environment, LZ short code).
module "naming" {
  source   = "../../../templates/utils"
  location = var.location
  project  = var.project
  lz       = "<FILL ME IN>"
  suffix   = var.environment
  lz_short = "<FILL ME IN>"
}

// Module: resource_group
// Purpose: Creates the {stack_name} resource group to contain all resources in this stack.
module "resource_group" {
  source           = "Azure/avm-res-resources-resourcegroup/azurerm"
  version          = "0.2.1"
  enable_telemetry = var.enable_telemetry
  location         = var.location
  name             = "${module.naming.name.resource_group}-{stack_name}"
  tags             = var.tags
}

