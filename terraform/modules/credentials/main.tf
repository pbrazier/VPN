terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_ssm_parameter" "tailscale_client_id" {
  name  = "/tailscale/oauth/client_id"
  type  = "SecureString"
  value = var.tailscale_client_id

  tags = {
    project = "tailscale"
  }
}

resource "aws_ssm_parameter" "tailscale_client_secret" {
  name  = "/tailscale/oauth/client_secret"
  type  = "SecureString"
  value = var.tailscale_client_secret

  tags = {
    project = "tailscale"
  }
}

variable "tailscale_client_id" {
  description = "Tailscale OAuth Client ID"
  type        = string
  sensitive   = true
}

variable "tailscale_client_secret" {
  description = "Tailscale OAuth Client Secret"
  type        = string
  sensitive   = true
}

output "parameter_name" {
  value = aws_ssm_parameter.tailscale_client_secret.name
}