resource "aws_ecs_cluster" "my_cluster" {
  name = "my-ecs-cluster"
}


resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "my-task-family"
  container_definitions    = jsonencode([
    {
      name  = "my-container"
      image = "nginx:latest"  // Change to your desired Docker image
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"] // Or ["EC2"] if using EC2 launch type
  cpu                      = "256"      // CPU units
  memory                   = "512"      // Memory in MiB
}


resource "aws_ecs_service" "my_service" {
  name            = "my-ecs-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  desired_count   = 2 // Change to your desired number of tasks
  launch_type     = "FARGATE" // Or "EC2" if using EC2 launch type

  network_configuration {
    subnets         = [data.terraform_remote_state.infrastructure.outputs.aws_pub_1,data.terraform_remote_state.infrastructure.outputs.aws_pub_2] // Specify your subnet IDs
    security_groups = [data.terraform_remote_state.platform.outputs.aws_jump_SG]  // Specify your security group IDs
    assign_public_ip = true
  }
}
