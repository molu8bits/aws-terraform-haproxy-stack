resource "aws_network_interface" "ec2-nic" {
  subnet_id       = var.subnet_id
  private_ips     = [var.private_ip]
  security_groups = var.security_group_id
}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.ec2-nic.id
  associate_with_private_ip = var.private_ip
}

data "template_file" "server" {
  template = file("${path.module}/haproxy-install-tls.sh")
  vars = {
    vm_name = "${var.vm_name}"
  }
}

resource "aws_instance" "ec2-vm" {
  depends_on           = [aws_eip.one]
  ami                  = var.ami
  instance_type        = var.instance_type
  key_name             = var.key_name
  iam_instance_profile = var.iam-instance-profile
  tags                 = merge(var.tags, { "Name" = var.vm_name })
  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.ec2-nic.id
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  user_data = data.template_file.server.rendered
}
