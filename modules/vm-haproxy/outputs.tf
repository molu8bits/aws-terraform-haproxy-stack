output "public_ip" {
  value = aws_instance.ec2-vm.public_ip
}

output "instance-id" {
  value = aws_instance.ec2-vm.id
}