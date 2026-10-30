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
  description = "Map of Transit Gateway instances and their attachment and routing configuration."
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.tgw_parameters : !(
        length(try(v.route_tables, {})) > 0 &&
        try(merge(var.tgw_defaults, v).create_tgw, true) != false &&
        try(merge(var.tgw_defaults, v).create_tgw_routes, true) != false
      )
    ])
    error_message = "tgw_parameters: route_tables requires create_tgw_routes = false. On an existing TGW this destroys the nested extra route table and its associations/propagations (see README migration notes)."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.tgw_parameters : [
        for vpc_key, vpc in try(v.vpc_attachments, {}) :
        length(try(v.route_tables, {})) == 0 || try(vpc.tgw_routes, null) == null
      ]
    ]))
    error_message = "tgw_parameters: vpc_attachments.*.tgw_routes is not used with route_tables. Move those routes to route_tables.<key>.static_routes."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.tgw_parameters : [
        for rt_key, rt in try(v.route_tables, {}) : [
          for route in try(rt.static_routes, []) :
          try(route.blackhole, false) == true || try(route.attachment, null) != null
        ]
      ]
    ]))
    error_message = "tgw_parameters: every route_tables.*.static_routes entry needs an attachment key or blackhole = true."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.tgw_parameters : [
        for att_key, att in try(v.attachments, {}) :
        anytrue([for f in ["id", "name", "owner_id", "resource_id"] : try(att[f], null) != null])
      ]
    ]))
    error_message = "tgw_parameters: every attachments entry needs id, name, owner_id or resource_id; without one the lookup matches every attachment of that type."
  }

  validation {
    condition = alltrue(flatten([
      for k, v in var.tgw_parameters : concat(
        [
          for rt_key, rt in try(v.route_tables, {}) : alltrue(concat(
            [for a in try(rt.propagations, []) : contains(concat(keys(try(v.vpc_attachments, {})), keys(try(v.attachments, {}))), a)],
            [for r in try(rt.static_routes, []) : try(r.attachment, null) == null || contains(concat(keys(try(v.vpc_attachments, {})), keys(try(v.attachments, {}))), try(r.attachment, ""))],
          ))
        ],
        [for vpc_key, vpc in try(v.vpc_attachments, {}) : try(vpc.transit_gateway_route_table, null) == null || contains(keys(try(v.route_tables, {})), try(vpc.transit_gateway_route_table, ""))],
        [for att_key, att in try(v.attachments, {}) : try(att.associate, null) == null || contains(keys(try(v.route_tables, {})), try(att.associate, ""))],
      )
    ]))
    error_message = "tgw_parameters: propagations and static_routes must name a vpc_attachments or attachments key, and transit_gateway_route_table / associate must name a route_tables key."
  }
}

variable "tgw_defaults" {
  type        = any
  description = "Default values merged into each entry of tgw_parameters."
  default     = {}
}
