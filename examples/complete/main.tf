module "wrapper_tgw" {
  source = "../../"

  metadata = local.metadata

  vpc_parameter = var.vpc_parameter

  tgw_parameters = {
    "tgw-01" = {
      # Variables to deploy transit gateway resource

      # create_tgw = true
      create_tgw_routes = false # Default: true. Must be false with route_tables (nested extra table + tgw_routes)

      # description                            = "Transit Gateway 01"
      # amazon_side_asn                        = "64512"
      # enable_default_route_table_association = true
      # enable_default_route_table_propagation = true
      # enable_multicast_support               = false
      # enable_vpn_ecmp_support                = true
      # enable_dns_support                     = true
      # enable_sg_referencing_support          = false
      # enable_encryption_support              = false
      # region                                 = "us-east-2" # Default: metadata.aws_region, then the provider region

      # transit_gateway_cidr_blocks    = []
      # transit_gateway_route_table_id = null

      ## Allow the sharing of the TGW using RAM
      share_tgw = true
      ## If enabled you can administer which accounts will have access to the TGW resources
      ram_principals = ["123456789"]
      # ram_allow_external_principals = false
      # ram_name                      = null
      enable_auto_accept_shared_attachments = true
      # WARNING: changing either flag from false to true REPLACES the Transit Gateway (true -> false is in place).
      # Default: true, or false when route_tables is set, so removing route_tables later also recreates the TGW.
      # Set both explicitly and keep them fixed once the TGW exists.
      enable_default_route_table_association = false
      enable_default_route_table_propagation = false

      ## Named TGW route tables (wrapper extension). Discover VPN/remote VPCs by Name tag.
      attachments = {
        vpn-01 = {
          resource_type = "vpn"
          name          = "example-vpn-01"
          associate     = "hybrid"
        }
        spoke = {
          name = "example-spoke-tgw-01-vpc-01"
        }
      }

      route_tables = {
        shared = {
          propagations = ["spoke", "vpn-01", "dev"]
        }
        hybrid = {
          propagations = ["prod"]
        }
        spoke = {
          propagations = ["vpn-01", "prod"]
          static_routes = [
            { destination_cidr_block = "0.0.0.0/0", attachment = "prod" },
          ]
        }
      }

      ## Managing TGW VPC Attachments
      vpc_attachments = {
        "prod" = {                                                                          //must be the same vpc_name
          subnet_ids   = ["private-us-east-1a", "private-us-east-1b", "private-us-east-1c"] // Only 1 Subnet per AZ
          dns_support  = true
          ipv6_support = false
          # Only set these in the TGW owner account. On a shared TGW (create_tgw = false) AWS ignores them
          # and the provider always reads true, so false shows a perpetual in-place diff. Omit them there;
          # association/propagation is managed from the owner account (route_tables / attachments).
          transit_gateway_default_route_table_association = false
          transit_gateway_default_route_table_propagation = false
          transit_gateway_route_table                     = "shared"
        }
        "dev" = {
          dns_support                 = true
          ipv6_support                = false
          subnet_ids                  = ["private-us-east-1a", "private-us-east-1b", "private-us-east-1c"] // Only 1 Subnet per AZ
          transit_gateway_route_table = "spoke"                                                            # Default assoc/prop then default to false
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
