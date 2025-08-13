variable "aws_region" {
  description = "AWS region for Lightsail instance"
  type        = string
  default     = "us-east-1"
}

variable "instance_name" {
  description = "Name for the Lightsail instance"
  type        = string
  
  validation {
    condition     = can(regex("^ts-[a-z]+$", var.instance_name))
    error_message = "Instance name must start with 'ts-' followed by lowercase letters only."
  }
}

variable "tailscale_api_key" {
  description = "Tailscale OAuth API key (only needed for initial credential setup)"
  type        = string
  sensitive   = true
  default     = null
}

variable "tailscale_tailnet" {
  description = "Tailscale tailnet name (only needed for initial credential setup)"
  type        = string
  default     = null
}