/*----------------------------------------------------------------------*/
/* Common |                                                             */
/*----------------------------------------------------------------------*/

variable "metadata" {
  type = any
}

variable "vpc_parameter" {
  type        = any
  description = "VPC wrapper outputs used to resolve vpc_id, subnet_ids, and route table IDs."
  default     = {}
}

/*----------------------------------------------------------------------*/
/* TGW | Variable Definition                                            */
/*----------------------------------------------------------------------*/
variable "tgw_parameters" {
  type        = any
  description = <<-EOT
    Map of Transit Gateway instances. Besides upstream keys, supports:
    - region: AWS region (default metadata.aws_region, then the provider region)
    - route_tables: named TGW route tables (propagations, static_routes, name). When set, create_tgw_routes is forced off.
    - attachments: extra attachments discovered by name, owner_id, resource_id, or id
    - vpc_attachments.*.transit_gateway_route_table: named table key to associate at attachment creation
    - create_tgw_routes: nested extra table + tgw_routes (not the AWS default tables); incompatible with route_tables
  EOT
  default     = {}
}

variable "tgw_defaults" {
  type        = any
  description = "Default values merged into each entry of tgw_parameters."
  default     = {}
}
