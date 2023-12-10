variable "ami" {
  type = string
}

variable "vm_name" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type = string
}

variable "security_group_id" {
  type = set(string)
}

variable "subnet_id" {
  type = string
}

variable "private_ip" {
  type = string
}

variable "iam-instance-profile" {
  type = string
}