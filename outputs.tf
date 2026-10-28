output "transit_gateway" {
  value = module.wrapper_tgw
}

output "route_table_ids" {
  description = "Named TGW route table IDs keyed by tgw then route table."
  value = {
    for tgw_key, tgw_config in var.tgw_parameters : tgw_key => {
      for rt_key, rt in try(tgw_config.route_tables, {}) :
      rt_key => local.route_table_ids["${tgw_key}/${rt_key}"]
    }
  }
}

output "route_table_arns" {
  description = "Named TGW route table ARNs for tables created in this stack."
  value = {
    for tgw_key, tgw_config in var.tgw_parameters : tgw_key => {
      for rt_key, rt in try(tgw_config.route_tables, {}) :
      rt_key => try(aws_ec2_transit_gateway_route_table.this["${tgw_key}/${rt_key}"].arn, null)
    }
  }
}

output "ram_resource_share_arns" {
  description = "RAM share ARN per named TGW route table."
  value = {
    for tgw_key, tgw_config in var.tgw_parameters : tgw_key => {
      for rt_key, rt in try(tgw_config.route_tables, {}) :
      rt_key => try(aws_ram_resource_share.route_table["${tgw_key}/${rt_key}"].arn, null)
    }
  }
}
