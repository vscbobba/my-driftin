resource "aws_instance" "monitor_instance" {
  ami                    = var.amazon_linux_2023
  instance_type          = "t2.small"
  subnet_id              = data.terraform_remote_state.infrastructure.outputs.aws_pub_1
  vpc_security_group_ids = [data.terraform_remote_state.platform.outputs.aws_jump_SG]
  key_name               = "driftin"
  tags = {
    Name = "monitor-server"
  }

  user_data = <<-EOF
    #!/bin/bash

    # Update the system
    sudo yum update -y

    # Install wget
    sudo yum install -y wget

    # Create directory for Loki
    sudo mkdir /opt/loki

    # Download Loki binary
    sudo wget -qO /opt/loki/loki.gz 'https://github.com/grafana/loki/releases/download/v3.0.0/loki-linux-amd64.zip'

    # Unzip the Loki binary
    sudo gunzip /opt/loki/loki.gz

    # Make the Loki binary executable
    sudo chmod a+x /opt/loki/loki

    # Create a symbolic link to the Loki binary
    sudo ln -s /opt/loki/loki /usr/local/bin/loki

    # Download the Loki local configuration file
    sudo wget -qO /opt/loki/loki-local-config.yaml 'https://raw.githubusercontent.com/grafana/loki/v3.0.0/cmd/loki/loki-local-config.yaml'

    # Create the Loki service file
    sudo bash -c 'cat <<EOF > /etc/systemd/system/loki.service
    [Unit]
    Description=Loki log aggregation system
    After=network.target

    [Service]
    ExecStart=/opt/loki/loki -config.file=/opt/loki/loki-local-config.yaml
    Restart=always

    [Install]
    WantedBy=multi-user.target
    EOF'

    # Start the Loki service
    sudo service loki start

    # Enable the Loki service to start on boot
    sudo systemctl enable loki

    # Restart the Loki service
    sudo systemctl restart loki

    # Check the status of the Loki service
    sudo service loki status
  EOF
}

resource "aws_cloudwatch_log_group" "cloudwatch_lg" {
  name = "${var.project_name}-${var.service}-${var.env}"
}

resource "aws_ecs_cluster" "jenkins_master_cluster" {
  name = "jenkins-master-cluster"
}

resource "aws_ecs_task_definition" "taskdefination" {
  family                   = "${var.project_name}-${var.service}-td-${var.env}"
  execution_role_arn       = "arn:aws:iam::631231558475:role/ecsTaskExecutionRole"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name  = "${var.project_name}-log-router-${var.service}-ct"
      image = "grafana/fluent-bit-plugin-loki:2.9.1"
      essential = true
      firelensConfiguration = {
        type = "fluentbit"
        options = {
          enable-ecs-log-metadata = "true"
        }
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "${var.project_name}-${var.service}-${var.env}"
          awslogs-region        = var.region
          awslogs-stream-prefix = "firelens"
        }
        secretOptions = []
      }
    },
    {
      name  = "${var.project_name}-${var.service}-ct"
      image = "631231558475.dkr.ecr.ap-south-1.amazonaws.com/jenkins:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awsfirelens"
        options = {
          Name  = "grafana-loki"
          Url   = "http://3.110.169.42:3100/loki/api/v1/push"
          Labels    =  "{job=\"firelens-${var.project_name}-${var.service}\",environment=\"${var.env}\"}"
          RemoveKeys    = "container_id,ecs_task_arn"
          LabelKeys = "container_name,ecs_task_definition,source,ecs_cluster"
          LineFormat    = "key_value"
        }
        secretOptions = []
      }
    }
  ])
}

resource "aws_ecs_service" "service" {
  name                               = "${var.project_name}-${var.service}-${var.env}"
  cluster                            = aws_ecs_cluster.jenkins_master_cluster.name
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 1
  enable_ecs_managed_tags            = false
  health_check_grace_period_seconds  = 0
  launch_type                        = "FARGATE"
  force_new_deployment               = true
  
  network_configuration {
    security_groups = [data.terraform_remote_state.platform.outputs.aws_jump_SG]
    subnets          = ["subnet-0806a2359ee968fba"]
    assign_public_ip = true
  }
  platform_version = "1.4.0"
  propagate_tags   = "SERVICE"
  task_definition  = aws_ecs_task_definition.taskdefination.arn
}