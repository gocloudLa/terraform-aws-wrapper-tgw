locals {
  create_tgw = {
    for tgw_key, tgw in local.tgws : tgw_key => merge(tgw, {
      vpc_attachments = {
        for vpc_key, vpc in try(tgw.vpc_attachments, {}) : vpc_key => {
          vpc_id = var.vpc_parameter.vpcs[vpc_key].vpc_id
          subnet_ids = [
            for subnet_id in vpc.subnet_ids :
            var.vpc_parameter.subnets["${vpc_key}-${subnet_id}"].id
          ]
          tgw_id                 = try(tgw.create_tgw, true) ? null : data.aws_ec2_transit_gateway.this[tgw_key].id
          appliance_mode_support = try(vpc.appliance_mode_support, false)
          dns_support            = try(vpc.dns_support, true)
          ipv6_support           = try(vpc.ipv6_support, false)
          # AWS default for VPC attachments is enable (the TGW-level default is disable).
          security_group_referencing_support              = try(vpc.security_group_referencing_support, true)
          transit_gateway_default_route_table_association = try(vpc.transit_gateway_default_route_table_association, try(vpc.transit_gateway_route_table, null) == null)
          transit_gateway_default_route_table_propagation = try(vpc.transit_gateway_default_route_table_propagation, try(vpc.transit_gateway_route_table, null) == null)
          tags                                            = merge(try(vpc.tags, local.common_tags), { Name = "${local.common_name}-${tgw_key}-${vpc_key}" })
        }
      }
    })
  }
}

module "wrapper_tgw" {
  source  = "terraform-aws-modules/transit-gateway/aws"
  version = "3.3.1"

  for_each = local.create_tgw

  region = local.tgw_region[each.key]

  create_tgw        = try(each.value.create_tgw, true)
  create_tgw_routes = try(each.value.create_tgw_routes, true)
  share_tgw         = try(each.value.share_tgw, false)

  name                                   = try(each.value.name, "${local.common_name}-${each.key}")
  description                            = try(each.value.description, null)
  amazon_side_asn                        = try(each.value.amazon_side_asn, "64512")
  enable_default_route_table_association = try(each.value.enable_default_route_table_association, length(try(each.value.route_tables, {})) == 0)
  enable_default_route_table_propagation = try(each.value.enable_default_route_table_propagation, length(try(each.value.route_tables, {})) == 0)
  enable_auto_accept_shared_attachments  = try(each.value.enable_auto_accept_shared_attachments, false)
  enable_multicast_support               = try(each.value.enable_multicast_support, false)
  enable_vpn_ecmp_support                = try(each.value.enable_vpn_ecmp_support, true)
  enable_dns_support                     = try(each.value.enable_dns_support, true)
  # AWS defaults; upstream 3.x defaults SG referencing to true, which would modify gateways created with 2.x.
  enable_sg_referencing_support = try(each.value.enable_sg_referencing_support, false)
  enable_encryption_support     = try(each.value.enable_encryption_support, false)

  ram_allow_external_principals = try(each.value.ram_allow_external_principals, false)
  ram_name                      = try(each.value.ram_name, "${local.common_name}-${each.key}")
  ram_principals                = try(each.value.ram_principals, [])
  ram_resource_share_arn        = try(each.value.ram_resource_share_arn, "")

  vpc_attachments                = each.value.vpc_attachments
  transit_gateway_cidr_blocks    = try(each.value.transit_gateway_cidr_blocks, [])
  transit_gateway_route_table_id = try(each.value.transit_gateway_route_table_id, null)

  tags = try(each.value.tags, local.common_tags)
}

locals {
  create_routes = merge(flatten([
    for tgw_key, tgw in local.tgws : [
      for vpc_name, vpc_values in try(tgw.vpc_routes, {}) : [
        for vpc_route_table_name, vpc_route_table_values in try(vpc_values, {}) : [
          for key in try(vpc_route_table_values.destination_cidr_block, vpc_route_table_values.destination_ipv6_cidr_block, []) : {
            "${vpc_name}-${vpc_route_table_name}-${key}" = {
              region                      = local.tgw_region[tgw_key]
              route_table_id              = var.vpc_parameter.route_tables["${vpc_name}-${vpc_route_table_name}"].id
              destination_cidr_block      = key
              destination_ipv6_cidr_block = null // to be supported with IPv6
              transit_gateway_id          = local.tgw_ids[tgw_key]
            }
          }
        ]
      ]
    ]
  ])...)
}

resource "aws_route" "transit_gateway" {
  for_each = local.create_routes

  region         = each.value.region
  route_table_id = each.value.route_table_id

  destination_cidr_block      = each.value.destination_cidr_block
  destination_ipv6_cidr_block = each.value.destination_ipv6_cidr_block

  transit_gateway_id = each.value.transit_gateway_id

  # CreateRoute returns InvalidTransitGatewayID.NotFound until the VPC attachment exists.
  depends_on = [module.wrapper_tgw]
}
