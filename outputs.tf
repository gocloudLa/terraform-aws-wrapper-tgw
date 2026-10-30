output "transit_gateway" {
  value = module.wrapper_tgw
}

output "route_table_ids" {
  description = "Named TGW route table IDs keyed by tgw then route table."
  value = {
    for tgw_key, tgw in local.tgws : tgw_key => {
      for rt_key, rt in try(tgw.route_tables, {}) :
      rt_key => try(local.route_table_ids["${tgw_key}/${rt_key}"], null)
    }
  }
}

output "route_table_arns" {
  description = "Named TGW route table ARNs, for tables created in this stack."
  value = {
    for tgw_key, tgw in local.tgws : tgw_key => {
      for rt_key, rt in try(tgw.route_tables, {}) :
      rt_key => try(aws_ec2_transit_gateway_route_table.this["${tgw_key}/${rt_key}"].arn, null)
    }
  }
}

