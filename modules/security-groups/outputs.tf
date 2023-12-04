output "sg-ssh-id" {
  value = aws_security_group.vpc-ssh.id
}

output "sg-web-id" {
  value = aws_security_group.vpc-web.id
}

output "sg-all-id" {
  //value = setunion(aws_security_group.vpc-ssh.id, aws_security_group.vpc-web.id)
  value = toset([aws_security_group.vpc-ssh.id, aws_security_group.vpc-web.id])
}