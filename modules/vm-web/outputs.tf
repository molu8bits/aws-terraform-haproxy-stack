output "public_ip" {
  value = aws_instance.ec2-vm.public_ip
}

/* output "public_ip" {
  value = aws_instance.ec2-vm.private_ip
} */