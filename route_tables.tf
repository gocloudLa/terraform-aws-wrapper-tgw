locals {
  tgw_ids = {
    for tgw_key, tgw_config in var.tgw_parameters : tgw_key => (
      lookup(tgw_config, "create_tgw", true) ? module.wrapper_tgw[tgw_key].ec2_transit_gateway_id : data.aws_ec2_transit_gateway.this[tgw_key].id
    )
  }

  route_tables = merge([
    for tgw_key, tgw_config in var.tgw_parameters : {
      for rt_key, rt in try(tgw_config.route_tables, {}) :
      "${tgw_key}/${rt_key}" => {
        tgw_key                       = tgw_key
        rt_key                        = rt_key
        create                        = try(rt.create, lookup(tgw_config, "create_tgw", true))
        share                         = try(rt.share, try(tgw_config.share_route_tables, length(try(tgw_config.ram_principals, [])) > 0))
        ram_share_name                = try(rt.ram_share_name, "${local.common_name}-tgw-rt-${rt_key}")
        ram_principals                = try(rt.ram_principals, try(tgw_config.ram_principals, []))
        ram_allow_external_principals = try(rt.ram_allow_external_principals, try(tgw_config.ram_allow_external_principals, false))
        tags                          = try(rt.tags, {})
        propagations                  = try(rt.propagations, [])
        static_routes                 = try(rt.static_routes, [])
      }
    }
  ]...)

  route_tables_create = { for k, v in local.route_tables : k => v if v.create }
  route_tables_lookup = { for k, v in local.route_tables : k => v if !v.create }

  discovered_attachments = merge([
    for tgw_key, tgw_config in var.tgw_parameters : {
      for att_key, att in try(tgw_config.attachments, {}) :
      "${tgw_key}/${att_key}" => {
        tgw_key       = tgw_key
        att_key       = att_key
        resource_type = try(att.resource_type, "vpc")
        name          = try(att.name, null)
        id            = try(att.id, null)
        associate     = try(att.associate, null)
      }
    }
  ]...)

  attachments_to_lookup = {
    for k, v in local.discovered_attachments : k => v if v.id == null
  }

  vpc_attachment_ids = merge([
    for tgw_key, tgw_config in var.tgw_parameters : {
      for vpc_key, vpc in try(tgw_config.vpc_attachments, {}) :
      "${tgw_key}/${vpc_key}" => module.wrapper_tgw[tgw_key].ec2_transit_gateway_vpc_attachment[vpc_key].id
    }
  ]...)

  discovered_attachment_ids = {
    for k, v in local.discovered_attachments : k => (
      v.id != null ? v.id : data.aws_ec2_transit_gateway_attachment.discovered[k].id
    )
  }

  attachment_ids = merge(local.discovered_attachment_ids, local.vpc_attachment_ids)

  vpc_associations = merge([
    for tgw_key, tgw_config in var.tgw_parameters : {
      for vpc_key, vpc in try(tgw_config.vpc_attachments, {}) :
      "${tgw_key}/${vpc_key}" => {
        attachment  = "${tgw_key}/${vpc_key}"
        route_table = "${tgw_key}/${vpc.transit_gateway_route_table}"
      } if try(vpc.transit_gateway_route_table, null) != null
    }
  ]...)

  discovered_associations = {
    for k, v in local.discovered_attachments : k => {
      attachment  = k
      route_table = "${v.tgw_key}/${v.associate}"
    } if v.associate != null
  }

  associations = merge(local.vpc_associations, local.discovered_associations)

  propagations = merge([
    for rt_key, rt in local.route_tables : {
      for attachment_key in rt.propagations :
      "${rt_key}:${attachment_key}" => {
        route_table = rt_key
        attachment  = "${rt.tgw_key}/${attachment_key}"
      }
    }
  ]...)

  static_routes = merge([
    for rt_key, rt in local.route_tables : {
      for route in rt.static_routes :
      "${rt_key}:${route.destination_cidr_block}" => {
        route_table            = rt_key
        destination_cidr_block = route.destination_cidr_block
        attachment             = try(route.attachment, null) != null ? "${rt.tgw_key}/${route.attachment}" : null
        blackhole              = try(route.blackhole, false)
      }
    }
  ]...)

  route_table_ids = merge(
    { for k, v in aws_ec2_transit_gateway_route_table.this : k => v.id },
    { for k, v in local.route_tables_lookup : k => reverse(split("/", one(data.aws_ram_resource_share.route_table[k].resource_arns)))[0] }
  )
}

resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each = local.route_tables_create

  transit_gateway_id = local.tgw_ids[each.value.tgw_key]

  tags = merge(local.common_tags, each.value.tags, {
    Name = each.value.ram_share_name
  })
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each = local.associations

  transit_gateway_attachment_id  = local.attachment_ids[each.value.attachment]
  transit_gateway_route_table_id = local.route_table_ids[each.value.route_table]
  replace_existing_association   = true
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = local.propagations

  transit_gateway_attachment_id  = local.attachment_ids[each.value.attachment]
  transit_gateway_route_table_id = local.route_table_ids[each.value.route_table]
}

resource "aws_ec2_transit_gateway_route" "this" {
  for_each = local.static_routes

  destination_cidr_block         = each.value.destination_cidr_block
  transit_gateway_route_table_id = local.route_table_ids[each.value.route_table]
  transit_gateway_attachment_id  = each.value.blackhole ? null : local.attachment_ids[each.value.attachment]
  blackhole                      = each.value.blackhole
}
