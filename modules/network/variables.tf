variable "cidr_vpc" {
  type = string
}

variable "cidr_subnet_1" {
  type = string
}

variable "cidr_subnet_2" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "vpc_name" {
  type    = string
  default = ""
}

variable "subnet_name_1" {
  type    = string
  default = ""
}

variable "subnet_name_2" {
  type    = string
  default = ""
}