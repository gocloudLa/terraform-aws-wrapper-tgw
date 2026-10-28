locals {
  ram_shares = {
    for k, v in local.route_tables_create : k => v if v.share && length(v.ram_principals) > 0
  }

  ram_principals = merge([
    for k, v in local.ram_shares : {
      for principal in v.ram_principals :
      "${k}:${principal}" => {
        route_table = k
        principal   = principal
      }
    }
  ]...)
}

# One share per named table so spoke accounts can resolve the table ID by share name
# (owner tags on RAM-shared TGW route tables are not visible to recipients).
resource "aws_ram_resource_share" "route_table" {
  for_each = local.ram_shares

  region                    = local.tgw_region[each.value.tgw_key]
  name                      = each.value.ram_share_name
  allow_external_principals = each.value.ram_allow_external_principals

  tags = merge(local.common_tags, each.value.tags, {
    Name = each.value.ram_share_name
  })
}

resource "aws_ram_principal_association" "route_table" {
  for_each = local.ram_principals

  region             = local.tgw_region[local.ram_shares[each.value.route_table].tgw_key]
  principal          = each.value.principal
  resource_share_arn = aws_ram_resource_share.route_table[each.value.route_table].arn
}

resource "aws_ram_resource_association" "route_table" {
  for_each = local.ram_shares

  region             = local.tgw_region[each.value.tgw_key]
  resource_arn       = aws_ec2_transit_gateway_route_table.this[each.key].arn
  resource_share_arn = aws_ram_resource_share.route_table[each.key].arn

  depends_on = [aws_ram_principal_association.route_table]
}
