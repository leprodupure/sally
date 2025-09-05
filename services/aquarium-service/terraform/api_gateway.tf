# --- API Gateway Integration ---
# This file will contain all API Gateway resources specific to the aquarium-service.
# This includes resources, methods, and integrations.

# Example for the /aquariums route:
resource "aws_api_gateway_resource" "aquariums" {
  rest_api_id = data.terraform_remote_state.core.outputs.api_gateway_id
  parent_id   = data.terraform_remote_state.core.outputs.api_gateway_root_resource_id
  path_part   = "aquariums"
}

# ... you would continue to define methods (GET, POST) and integrations here ...

# Note: The root resource ID of the API Gateway needs to be exported from the core-infra module.
# Add the following to services/core-infra/outputs.tf:
#
# output "api_gateway_root_resource_id" {
#   description = "The ID of the root resource for the core API Gateway."
#   value       = aws_api_gateway_rest_api.main.root_resource_id
# }