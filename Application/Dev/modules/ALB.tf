resource "aws_instance" "Jumpserver" {
   instance_type = var.jump_type
   ami = var.jump_ami
   key_name = "driftin"
   subnet_id = data.terraform_remote_state.infrastructure.outputs.aws_priv_1
   vpc_security_group_ids = ["${data.terraform_remote_state.platform.outputs.aws_jump_SG}"]
   user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y nginx
              sudo service nginx restart
              EOF
}

output "aws_jump"{
    value = aws_instance.Jumpserver.private_ip
}

resource "aws_lb" "my_load_balancer" {
  name               = "my-load-balancer"
  internal           = false
  load_balancer_type = "application"
  subnets            = [data.terraform_remote_state.infrastructure.outputs.aws_pub_1,data.terraform_remote_state.infrastructure.outputs.aws_pub_2]  # List your subnets here
  security_groups    = ["${data.terraform_remote_state.platform.outputs.aws_jump_SG}"]  # Specify your security group IDs
}

resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.infrastructure.outputs.aws_vpc           # Specify your VPC ID

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}
resource "aws_lb_target_group_attachment" "TG_attachment" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id        = aws_instance.Jumpserver.id
}

#NAT should be installed from Infrastructure configuration

