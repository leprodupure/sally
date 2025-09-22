output "vpc_id" {
  description = "The ID of the main VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "A list of IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "A list of IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidr_blocks" {
  description = "A list of CIDR blocks of the private subnets."
  value       = aws_subnet.private[*].cidr_block
}

output "db_credentials_secret_arn" {
  description = "The ARN of the secret containing the database credentials."
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_security_group_id" {
  description = "The ID of the security group for the database."
  value       = aws_security_group.db.id
}
