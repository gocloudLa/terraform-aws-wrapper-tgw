locals {
  region = try(local.metadata.aws_region, data.aws_region.current.region)

  # tgw_defaults merged under each entry, so every read below is try(each.value.x, <default>).
  tgws = {
    for tgw_key, tgw_config in var.tgw_parameters :
    tgw_key => merge(var.tgw_defaults, tgw_config) if length(try(tgw_config, {})) > 0
  }

  tgw_region = {
    for tgw_key, tgw in local.tgws : tgw_key => try(tgw.region, local.region)
  }

  tgw_ids = {
    for tgw_key, tgw in local.tgws : tgw_key => (
      try(tgw.create_tgw, true) ? module.wrapper_tgw[tgw_key].ec2_transit_gateway_id : data.aws_ec2_transit_gateway.this[tgw_key].id
    )
  }
}
