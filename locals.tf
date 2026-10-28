locals {
  tgw_region = {
    for tgw_key, tgw_config in var.tgw_parameters :
    tgw_key => try(tgw_config.region, var.tgw_defaults.region, local.region)
  }
}
