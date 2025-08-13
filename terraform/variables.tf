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