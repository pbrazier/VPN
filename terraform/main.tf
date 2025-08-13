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
  region = var.aws_region
}

provider "tailscale" {
  api_key = data.aws_ssm_parameter.tailscale_api_key.value
  tailnet = data.aws_ssm_parameter.tailscale_tailnet.value
}

# Generate Tailscale auth key
resource "tailscale_tailnet_key" "exit_node_key" {
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 3600 # 1 hour - enough for deployment
  description   = "Auto-generated key for ${var.instance_name}"
  tags          = ["tag:AwsLightsail"]
}

# User data script for Lightsail instance
locals {
  user_data = templatefile("${path.module}/user-data.sh", {
    instance_name = var.instance_name
    auth_key     = tailscale_tailnet_key.exit_node_key.key
  })
}

# Lightsail instance
resource "aws_lightsail_instance" "tailscale_exit_node" {
  name              = var.instance_name
  availability_zone = "${var.aws_region}a"
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