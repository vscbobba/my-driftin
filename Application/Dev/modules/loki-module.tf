resource "aws_cloudwatch_log_group" "cloudwatch_lg" {
  name = "${var.project_name}-${var.service}-${var.env}"
}

resource "aws_ecs_cluster" "jenkins_master_cluster" {
  name = "jenkins-master-cluster"
}

module "fluentbit_definition" {
  source          = "cloudposse/ecs-container-definition/aws"
  version         = "0.58.1"
  container_image = "grafana/fluent-bit-plugin-loki:2.9.1"
  container_name  = "${var.project_name}-log-router-${var.service}-ct"
  firelens_configuration = {
    type = "fluentbit"
    options = {
      enable-ecs-log-metadata = "true"
    }
  }
  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = "${var.project_name}-${var.service}-${var.env}"
      awslogs-region        = var.region
      awslogs-stream-prefix = "firelens"
    }
    secretOptions = []
  }
}

module "app_definition" {
  source          = "cloudposse/ecs-container-definition/aws"
  version         = "0.58.1"
  container_image = "631231558475.dkr.ecr.ap-south-1.amazonaws.com/jenkins:latest"
  container_name  = "${var.project_name}-${var.service}-ct"
  #container_cpu   = var.container_cpu
  #container_memory = var.container_memory
  port_mappings = [{
    containerPort = 8080
    hostPort      = 8080
    protocol      = "tcp"
  }]

  log_configuration = {
    logDriver = "awsfirelens"
    options = {
      Name  = "grafana-loki"
      Url   = "http://13.127.225.87:3100/loki/api/v1/push"    #https://${var.grafana_username}:${var.grafana_password}@${var.grafana_host}/loki/api/v1/push"
      Labels    =  "{job=\"firelens-${var.project_name}-${var.service}\",environment=\"${var.env}\"}"
      RemoveKeys    = "container_id,ecs_task_arn"
      LabelKeys = "container_name,ecs_task_definition,source,ecs_cluster"
      LineFormat    = "key_value"
    }
    secretOptions = []
  }
}

resource "aws_ecs_task_definition" "taskdefination" {
  family                   = "${var.project_name}-${var.service}-td-${var.env}"
  execution_role_arn       = "arn:aws:iam::631231558475:role/ecsTaskExecutionRole"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    module.fluentbit_definition.json_map_object,
    module.app_definition.json_map_object
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