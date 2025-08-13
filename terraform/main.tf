terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.15"
    }
  }
}

provider "aws" {
  region = local.aws_region
}

# Provider for London region (master credential storage)
provider "aws" {
  alias  = "london"
  region = "eu-west-2"
}

# Read existing credentials from London region
data "aws_ssm_parameter" "tailscale_client_secret" {
  provider = aws.london
  name     = "/tailscale/oauth/client_secret"
}

provider "tailscale" {
  api_key = data.aws_ssm_parameter.tailscale_client_secret.value
}

# Generate Tailscale auth key
resource "tailscale_tailnet_key" "exit_node_key" {
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 3600 # 1 hour - enough for deployment
  description   = "Auto-generated key for ${local.instance_name}"
  # tags          = ["tag:awslightsail"] # Removed to test permissions
}

# User data script for Lightsail instance
locals {
  user_data = templatefile("${path.module}/user-data.sh", {
    instance_name = local.instance_name
    auth_key     = tailscale_tailnet_key.exit_node_key.key
  })
}

# Lightsail instance
resource "aws_lightsail_instance" "tailscale_exit_node" {
  name              = local.instance_name
  availability_zone = "${local.aws_region}a"
  blueprint_id      = "amazon_linux_2023"
  bundle_id         = "nano_3_0"
  user_data         = local.user_data

  tags = {
    project = "tailscale"
  }
}

# Close unnecessary ports for security
resource "aws_lightsail_instance_public_ports" "tailscale_exit_node_ports" {
  instance_name = aws_lightsail_instance.tailscale_exit_node.name

  port_info {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidrs     = ["0.0.0.0/0"]  # Lightsail browser SSH only
  }
}