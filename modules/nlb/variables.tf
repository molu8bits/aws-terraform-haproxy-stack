variable "subnets" {
  type = set(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "vpc_id" {
  type = string
}

variable "target_instance" {
  type = string
}

/* variable "target_instances" {
  type = set(string)
}
 */
