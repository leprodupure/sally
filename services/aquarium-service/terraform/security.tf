# This resource creates a rule in the database's security group to allow
# inbound traffic from this service's Lambda function.
# This is the correct way to manage cross-service security rules, as this
# service is responsible for managing its own access.

resource "aws_security_group_rule" "allow_lambda_to_db" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda.id
  security_group_id        = data.terraform_remote_state.core.outputs.db_security_group_id
}