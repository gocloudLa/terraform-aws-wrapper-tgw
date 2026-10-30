data "aws_region" "current" {}

/*----------------------------------------------------------------------*/
/* Network | datasources                                                */
/*----------------------------------------------------------------------*/
data "aws_ec2_transit_gateway" "this" {
  for_each = { for k, v in local.tgws : k => v if !try(v.create_tgw, true) }

  region = local.tgw_region[each.key]

  filter {
    name   = "options.amazon-side-asn"
    values = try(tolist(each.value.amazon_side_asn), [tostring(try(each.value.amazon_side_asn, "64512"))])
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
    name   = "state"
    values = ["available"]
  }

  # Tags on a cross-account attachment belong to the account that created it and are
  # not visible to the TGW owner. Use owner_id (resource-owner-id) or resource_id for
  # spoke VPCs; use name only for attachments created in the TGW owner account (VPN, local VPC).
  dynamic "filter" {
    for_each = each.value.name != null ? [each.value.name] : []
    content {
      name   = "tag:Name"
      values = [filter.value]
    }
  }

  dynamic "filter" {
    for_each = each.value.owner_id != null ? [each.value.owner_id] : []
    content {
      name   = "resource-owner-id"
      values = [filter.value]
    }
  }

  dynamic "filter" {
    for_each = each.value.resource_id != null ? [each.value.resource_id] : []
    content {
      name   = "resource-id"
      values = [filter.value]
    }
  }
}

# route_tables entries with create = false: an existing table on the same TGW, by id or Name tag.
data "aws_ec2_transit_gateway_route_table" "existing" {
  for_each = local.route_tables_existing

  region = local.tgw_region[each.value.tgw_key]
  id     = each.value.id

  filter {
    name   = "transit-gateway-id"
    values = [local.tgw_ids[each.value.tgw_key]]
  }

  dynamic "filter" {
    for_each = each.value.id == null ? [each.value.name] : []
    content {
      name   = "tag:Name"
      values = [filter.value]
    }
  }
}
