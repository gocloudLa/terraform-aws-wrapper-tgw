/*----------------------------------------------------------------------*/
/* Common |                                                             */
/*----------------------------------------------------------------------*/

variable "metadata" {
  type = any
}

variable "vpc_parameter" {
  type        = any
  description = "vpc parameteres to configure tgw module"
  default     = {}
}

/*----------------------------------------------------------------------*/
/* TGW | Variable Definition                                            */
/*----------------------------------------------------------------------*/
variable "tgw_parameters" {
  type        = any
  description = "tgw parameteres to configure tgw module"
  default     = {}
}

variable "tgw_defaults" {
  type        = any
  description = "tgw defaults parameteres to configure tgw module"
  default     = {}
}
