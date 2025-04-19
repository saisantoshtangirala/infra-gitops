provider "aws" {
  region = "us-east-1"
}

data "aws_secretsmanager_secret_version" "db" {
  secret_id = "db_credentials"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.18.1"
  name    = "gitops-vpc"
  cidr    = "10.0.0.0/16"
  azs     = ["us-east-1a", "us-east-1b"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
}

# Sample ECS Service with secret env vars
module "ecs" {
  source = "terraform-aws-modules/ecs/aws"
  name   = "web-app"

  container_definitions = jsonencode([
    {
      name      = "web"
      image     = "myrepo/web:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      environment = [
        {
          name  = "DB_USER"
          value = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)["username"]
        },
        {
          name  = "DB_PASS"
          value = jsondecode(data.aws_secretsmanager_secret_version.db.secret_string)["password"]
        }
      ]
    }
  ])
}
