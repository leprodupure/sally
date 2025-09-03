# --- Database Credentials ---
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.project_name}/${var.environment}/${var.module_name}/db_credentials"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    url      = aws_db_instance.main.address
    db_name  = var.project_name
  })
}

# --- Database Resources ---
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-${var.module_name}-sng"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-${var.environment}-${var.module_name}-sng"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.project_name}-${var.environment}-${var.module_name}-db-sg"
  description = "Allow PostgreSQL traffic from within the VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block] # Allows access from any resource in the VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "main" {
  identifier             = "${var.project_name}-${var.environment}-${var.module_name}-db"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro" # Free Tier eligible
  allocated_storage      = 20            # Free Tier eligible
  storage_type           = "gp2"
  username               = var.db_username
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot    = true
}
