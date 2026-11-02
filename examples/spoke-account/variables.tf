/*----------------------------------------------------------------------*/
/* VPC Parameters | Variable Definition                                 */
/*----------------------------------------------------------------------*/
variable "vpc_parameter" {
  type        = any
  description = "VPC wrapper outputs used to resolve vpc_id, subnet_ids, and route table IDs."
  default     = {}
}
