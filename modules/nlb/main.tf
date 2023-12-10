resource "aws_lb" "nlb" {
  name                       = "haproxy-lab-nlb"
  internal                   = false
  load_balancer_type         = "network"
  subnets                    = var.subnets
  enable_deletion_protection = false
  tags                       = var.tags
}

resource "aws_lb_target_group" "lb-target-group" {
  name     = "haproxy-lab"
  port     = 80
  protocol = "TCP"
  vpc_id   = var.vpc_id
  health_check {
    enabled             = true
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group_attachment" "lb-2-target-group" {
  target_group_arn = aws_lb_target_group.lb-target-group.id
  target_id        = var.target_instance
}

resource "aws_lb_listener" "tcp80" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "80"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-target-group.arn
  }
}

resource "aws_lb_listener" "tcp443" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "443"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb-target-group.arn
  }
}
