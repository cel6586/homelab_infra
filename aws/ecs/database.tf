resource "aws_db_subnet_group" "main" {
  name       = "game-tracker"
  subnet_ids = aws_subnet.private[*].id

  tags = { Name = "game-tracker" }
}

resource "aws_db_instance" "main" {
  identifier = "game-tracker"

  engine         = "postgres"
  engine_version = "17"
  instance_class = "db.t4g.micro"

  allocated_storage = 20
  storage_encrypted = true

  db_name                     = "gametracker"
  username                    = "gtadmin"
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  multi_az            = false
  skip_final_snapshot = true
}