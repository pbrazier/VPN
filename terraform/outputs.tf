output "instance_name" {
  description = "Name of the created Lightsail instance"
  value       = aws_lightsail_instance.tailscale_exit_node.name
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = aws_lightsail_instance.tailscale_exit_node.public_ip_address
}

output "region" {
  description = "AWS region where instance was created"
  value       = var.aws_region
}

output "monthly_cost" {
  description = "Estimated monthly cost in USD"
  value       = "$3.50"
}