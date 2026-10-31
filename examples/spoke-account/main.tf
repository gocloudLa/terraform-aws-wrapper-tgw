# Spoke account: attach local VPCs to a Transit Gateway shared from the network account through RAM.
# Association and propagation are managed in the TGW owner account (route_tables + attachments there).
module "wrapper_tgw" {
  source = "../../"

  metadata = local.metadata

  vpc_parameter = var.vpc_parameter

  tgw_parameters = {
    "tgw-01" = {
      create_tgw      = false   # Default: true. Use the shared TGW instead of creating one
      amazon_side_asn = "64512" # Finds the shared TGW by ASN; use a unique ASN if several TGWs are visible

      vpc_attachments = {
        "prod" = {
          subnet_ids   = ["private-us-east-1a", "private-us-east-1b", "private-us-east-1c"] // Only 1 Subnet per AZ
          dns_support  = true
          ipv6_support = false
          # Do not set transit_gateway_default_route_table_association / _propagation here: on a shared TGW
          # AWS ignores them and the provider always reads true, so false shows a perpetual in-place diff.
        }
      }

      ## Routes from the spoke VPC toward the TGW (other VPCs and on-premises)
      vpc_routes = {
        "prod" = {
          "private" = { destination_cidr_block = ["10.20.0.0/16", "10.60.0.0/16"] }
          "public"  = { destination_cidr_block = ["10.20.0.0/16", "10.60.0.0/16"] }
        }
      }
    }
  }
}
