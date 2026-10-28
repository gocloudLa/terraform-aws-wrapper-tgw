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
    - route_tables: named TGW route tables (propagations, static_routes, create/share/ram_share_name)
    - attachments: extra attachments discovered by Name (or pinned by id) for association/propagation
    - vpc_attachments.*.transit_gateway_route_table: named table key to associate at attachment creation
    - share_route_tables: RAM-share created tables with ram_principals (default true when ram_principals is set)
  EOT
  default     = {}
}

variable "tgw_defaults" {
  type        = any
  description = "Default values merged into each entry of tgw_parameters."
  default     = {}
}
