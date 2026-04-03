/*----------------------------------------------------------------------*/
/* Common |                                                             */
/*----------------------------------------------------------------------*/

# variable "metadata" {
#   type = any
# }

/*----------------------------------------------------------------------*/
/* VPC Parameters | Variable Definition                                 */
/*----------------------------------------------------------------------*/
variable "vpc_parameters" {
  type        = any
  description = "VPC parameters to configure multiple VPC, TGW and VPN resources"
  default     = {}
}