/*----------------------------------------------------------------------*/
/* Network | datasources                                                */
/*----------------------------------------------------------------------*/
data "aws_ec2_transit_gateway" "this" {
  for_each = { for k, v in var.tgw_parameters : k => v if(try(v.create_tgw, true) != true) }

  filter {
    name   = "options.amazon-side-asn"
    values = lookup(each.value, "amazon_side_asn", ["64512"])
  }

}
