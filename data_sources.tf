data "aws_region" "current" {}

/*----------------------------------------------------------------------*/
/* Network | datasources                                                */
/*----------------------------------------------------------------------*/
data "aws_ec2_transit_gateway" "this" {
  for_each = { for k, v in var.tgw_parameters : k => v if(try(v.create_tgw, true) != true) }

  region = local.tgw_region[each.key]

  filter {
    name = "options.amazon-side-asn"
    values = try(
      tolist(each.value.amazon_side_asn),
      [tostring(lookup(each.value, "amazon_side_asn", "64512"))]
    )
  }
}

data "aws_ec2_transit_gateway_attachment" "discovered" {
  for_each = local.attachments_to_lookup

  region = local.tgw_region[each.value.tgw_key]

  filter {
    name   = "transit-gateway-id"
    values = [local.tgw_ids[each.value.tgw_key]]
  }

  filter {
    name   = "resource-type"
    values = [each.value.resource_type]
  }

  filter {
    name   = "tag:Name"
    values = [each.value.name]
  }
}

data "aws_ram_resource_share" "route_table" {
  for_each = local.route_tables_lookup

  region                = local.tgw_region[each.value.tgw_key]
  name                  = each.value.ram_share_name
  resource_owner        = "OTHER-ACCOUNTS"
  resource_share_status = "ACTIVE"
}
