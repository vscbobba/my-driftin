resource "aws_ecs_cluster" "jenkins_master_cluster" {
  name = "jenkins-master-cluster"
}
resource "aws_ecs_cluster" "jenkins_slave_cluster" {
  name = "jenkins-slave-cluster"
}
resource "aws_cloudwatch_log_group" "ecs_log_jenkins_master" {
   name = "/ecs/jenkins-master"
   retention_in_days = 1
}
resource "aws_cloudwatch_log_group" "ecs_log_jenkins_slave" {
   name = "/ecs/jenkins-slave"
   retention_in_days = 1
}

resource "aws_ecs_task_definition" "jenkins_master" {
  family                   = "jenkins-master"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = "arn:aws:iam::631231558475:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name      = "jenkins-master"
      image     = "jenkins/jenkins:lts"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        },
        {
          containerPort = 50000
          hostPort      = 50000
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "${aws_cloudwatch_log_group.ecs_log_jenkins_master.name}"
          "awslogs-region"        = "ap-south-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "jenkins_slave" {
  family                   = "jenkins-slave"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::631231558475:role/ecsTaskExecutionRole"

  container_definitions = jsonencode([
    {
      name      = "jenkins-slave"
      image     = "jenkins/jnlp-slave:latest"
      essential = true
       environment = [
        {
          name  = "JENKINS_URL"
          value = "http://${aws_ecs_service.jenkins_master_service.name}:8080"
        },
        {
          name  = "JENKINS_SECRET"
          value = "myjenkins"  // Replace with actual secret
        },
        {
          name  = "JENKINS_AGENT_NAME"
          value = "jenkins-slave"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "${aws_cloudwatch_log_group.ecs_log_jenkins_slave.name}"
          "awslogs-region"        = "ap-south-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "jenkins_master_service" {
  name            = "jenkins-master-service"
  cluster         = aws_ecs_cluster.jenkins_master_cluster.id
  task_definition = aws_ecs_task_definition.jenkins_master.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [data.terraform_remote_state.infrastructure.outputs.aws_pub_1,data.terraform_remote_state.infrastructure.outputs.aws_pub_2] // Specify your subnet IDs
    security_groups = [data.terraform_remote_state.platform.outputs.aws_jump_SG]  // Specify your security group IDs
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "jenkins_slave_service" {
  name            = "jenkins-slave-service"
  cluster         = aws_ecs_cluster.jenkins_slave_cluster.id
  task_definition = aws_ecs_task_definition.jenkins_slave.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [data.terraform_remote_state.infrastructure.outputs.aws_pub_1,data.terraform_remote_state.infrastructure.outputs.aws_pub_2] // Specify your subnet IDs
    security_groups = [data.terraform_remote_state.platform.outputs.aws_jump_SG]  // Specify your security group IDs
    assign_public_ip = true
  }
}