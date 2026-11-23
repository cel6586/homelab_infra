resource "aws_ecs_cluster" "main" {
  name = "game-tracker"
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/game-tracker"
  retention_in_days = 7
}