# LEGACY: single extra TGW route table (create_tgw_routes = true) with per-attachment tgw_routes.
# The wrapper does not forward vpc_attachments.*.tgw_routes to the upstream module, so those routes are
# not created. Kept for reference only; new stacks should use route_tables (see examples/complete).
module "wrapper_tgw" {
  source = "../../"

  metadata = local.metadata

  vpc_parameter = var.vpc_parameter

  tgw_parameters = {
    "tgw-01" = {
      # create_tgw        = true
      # create_tgw_routes = true # Default: true. Creates the extra table (no route_tables in this mode)

      ## Allow the sharing of the TGW using RAM
      share_tgw = true
      ## If enabled you can administer which accounts will have access to the TGW resources
      ram_principals                        = ["123456789012"]
      enable_auto_accept_shared_attachments = true

      ## Managing TGW VPC Attachments
      vpc_attachments = {
        "prod" = {                                                                          //must be the same vpc_name
          subnet_ids   = ["private-us-east-1a", "private-us-east-1b", "private-us-east-1c"] // Only 1 Subnet per AZ
          dns_support  = true
          ipv6_support = false
          # true: stays on the AWS default tables. false: associates/propagates to the extra table.
          transit_gateway_default_route_table_association = true
          transit_gateway_default_route_table_propagation = true
          tgw_routes = [ # Legacy: not forwarded by the wrapper (no effect)
            {
              destination_cidr_block = "10.15.0.0/16"
            },
            {
              blackhole              = true
              destination_cidr_block = "0.0.0.0/0"
            }
          ]
        }
        "dev" = {
          dns_support                                     = true
          ipv6_support                                    = false
          subnet_ids                                      = ["private-us-east-1a", "private-us-east-1b", "private-us-east-1c"] // Only 1 Subnet per AZ
          transit_gateway_default_route_table_association = true
          transit_gateway_default_route_table_propagation = true
          tgw_routes = [ # Legacy: not forwarded by the wrapper (no effect)
            {
              destination_cidr_block = "10.16.0.0/16"
            },
            {
              blackhole              = true
              destination_cidr_block = "0.0.0.0/0"
            }
          ]
        }
      }

      ## Routes from each VPC route table toward the TGW
      vpc_routes = {
        "prod" = {
          "private" = { destination_cidr_block = ["10.16.0.0/16", "10.17.0.0/16"] }
          "public"  = { destination_cidr_block = ["10.16.0.0/16", "10.17.0.0/16"] }
        }
        "dev" = {
          "private" = { destination_cidr_block = ["10.15.0.0/16", "10.17.0.0/16"] }
          "public"  = { destination_cidr_block = ["10.15.0.0/16", "10.17.0.0/16"] }
        }
      }
    }
  }
}
