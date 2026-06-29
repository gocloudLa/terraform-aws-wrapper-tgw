module "wrapper_tgw" {
  source = "../../"

  metadata = local.metadata

  vpc_parameter = var.vpc_parameter

  tgw_parameters = {
    "tgw-01" = {
      # Variables to deploy transit gateway resource

      # create_tgw = true
      # create_tgw_routes = false

      # description                            = "Transit Gateway 01"
      # amazon_side_asn                        = "64512"
      # enable_default_route_table_association = true
      # enable_default_route_table_propagation = true
      # enable_multicast_support               = false
      # enable_vpn_ecmp_support                = true
      # enable_dns_support                     = true

      # transit_gateway_cidr_blocks    = []
      # transit_gateway_route_table_id = null

      ## Allow the sharing of the TGW using RAM
      share_tgw = true
      ## If enabled you can administer which accounts will have access to the TGW resources
      ram_principals = ["123456789"]
      # ram_allow_external_principals = false
      # ram_name                      = null
      enable_auto_accept_shared_attachments = true

      ## Managing TGW VPC Attachments
      vpc_attachments = {
        "prod" = {                                                                                                             //must be the same vpc_name
          subnet_ids                                      = ["private-us-east-1a", "private-us-east-1b", "private-us-east-1c"] // Only 1 Subnet per AZ
          dns_support                                     = true
          ipv6_support                                    = false
          transit_gateway_default_route_table_association = true
          transit_gateway_default_route_table_propagation = true
          tgw_routes = [
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
          tgw_routes = [
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
      ## Managing route association of route tables of attached VPC's
      vpc_routes = {
        "prod" = {
          "private" = {
            destination_cidr_block = [
              "10.16.0.0/16", # TEST2
              "10.17.0.0/16"  # TEST3
            ]
          }
          "public" = {
            destination_cidr_block = [
              "10.16.0.0/16", # TEST2
              "10.17.0.0/16"  # TEST3
            ]
          }
        }
        "dev" = {
          "private" = {
            destination_cidr_block = [
              "10.15.0.0/16", # TEST1
              "10.17.0.0/16"  # TEST3
            ]
          }
          "public" = {
            destination_cidr_block = [
              "10.15.0.0/16", # TEST1
              "10.17.0.0/16"  # TEST3
            ]
          }
        }
      }
    }
  }
}
