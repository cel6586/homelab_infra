data "aws_ecr_repository" "api" {
  name = "game-tracker-api"
}

data "aws_ecr_repository" "web" {
  name = "game-tracker-web"
}

resource "aws_service_discovery_http_namespace" "main" {
  name = "game-tracker"
}

resource "aws_ecs_task_definition" "api" {
  container_definitions = jsonencode([
    {
      name         = "api"
      image        = "${data.aws_ecr_repository.api.repository_url}:${var.image_tag}"
      essential    = true
      portMappings = [{ name = "api", containerPort = 8000, appProtocol = "http" }]

      environment = [
        { name = "DB_HOST", value = aws_db_instance.main.address },
        { name = "DB_NAME", value = aws_db_instance.main.db_name },
        { name = "DB_USER", value = aws_db_instance.main.username },
      ]

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_db_instance.main.master_user_secret[0].secret_arn}:password::"
        },
        {
          name      = "SECRET_KEY"
          valueFrom = "${data.aws_secretsmanager_secret.app.arn}:SECRET_KEY::"
        },
        {
          name      = "SIGNUP_CODE"
          valueFrom = "${data.aws_secretsmanager_secret.app.arn}:SIGNUP_CODE::"
        },
        {
          name      = "IGDB_CLIENT_ID"
          valueFrom = "${data.aws_secretsmanager_secret.app.arn}:IGDB_CLIENT_ID::"
        },
        {
          name      = "IGDB_CLIENT_SECRET"
          valueFrom = "${data.aws_secretsmanager_secret.app.arn}:IGDB_CLIENT_SECRET::"
        },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.main.name
          awslogs-region        = "us-east-2"
          awslogs-stream-prefix = "api"
        }
      }
    }
  ])
  family                   = "game-tracker-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn
}

resource "aws_ecs_task_definition" "web" {
  container_definitions = jsonencode([
    {
      name         = "web"
      image        = "${data.aws_ecr_repository.web.repository_url}:${var.image_tag}"
      essential    = true
      portMappings = [{ name = "web", containerPort = 8080, appProtocol = "http" }]
      environment  = [{ name = "API_UPSTREAM", value = "http://api:8000" }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.main.name
          awslogs-region        = "us-east-2"
          awslogs-stream-prefix = "web"
        }
      }
    }
  ])
  family                   = "game-tracker-web"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn
}