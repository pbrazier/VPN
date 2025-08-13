output "api_key_parameter_name" {
  description = "SSM parameter name for API key"
  value       = aws_ssm_parameter.tailscale_api_key.name
}

output "tailnet_parameter_name" {
  description = "SSM parameter name for tailnet"
  value       = aws_ssm_parameter.tailscale_tailnet.name
}