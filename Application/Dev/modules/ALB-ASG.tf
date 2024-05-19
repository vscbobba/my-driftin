#Load balancer
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

# Launch templates
resource "aws_launch_template" "sample-servers" {
  name_prefix          = "example-lc"
  image_id             = var.jump_ami
  instance_type        = var.jump_type
  vpc_security_group_ids = ["${data.terraform_remote_state.platform.outputs.aws_jump_SG}"]
  key_name             = "driftin"
  user_data            =  base64encode(file("${path.module}/user_data.sh"))
}

#ASG
resource "aws_autoscaling_group" "ASG" {
  name                 = "sample-asg"
  launch_template {
     id = aws_launch_template.sample-servers.id
  }
  vpc_zone_identifier = ["${data.terraform_remote_state.infrastructure.outputs.aws_priv_1}"]
  min_size             = 2
  max_size             = 5
  desired_capacity     = 3
  tag {
    key                 = "Name"
    value               = "sample-instance"
    propagate_at_launch = true
  }

  target_group_arns = [aws_lb_target_group.my_target_group.arn]
}


#NAT should be installed from Infrastructure configuration
# SG to allow ALB to show in web browser

