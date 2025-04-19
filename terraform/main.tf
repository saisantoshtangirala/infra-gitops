resource "aws_ecs_cluster" "main" {
  name = "web-app-cluster"
}

resource "aws_ecs_task_definition" "web_task" {
  family                   = "web-task"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = "256"
  memory                  = "512"
  execution_role_arn      = aws_iam_role.ecs_task_exec.arn
  task_role_arn           = aws_iam_role.ecs_task_exec.arn

  container_definitions = jsonencode([
    {
      name      = "web"
      image     = "myrepo/web:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "DB_USER"
          value = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)["username"]
        },
        {
          name  = "DB_PASS"
          value = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)["password"]
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "web_service" {
  name            = "web-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = module.vpc.public_subnets
    assign_public_ip = true
    security_groups  = [aws_security_group.web_sg.id]
  }
}

resource "aws_iam_role" "ecs_task_exec" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_attach" {
  role       = aws_iam_role.ecs_task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
