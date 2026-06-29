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
}

variable "tgw_defaults" {
  type        = any
  description = "Default values merged into each entry of tgw_parameters."
  default     = {}
}
