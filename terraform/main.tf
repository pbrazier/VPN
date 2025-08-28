terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.16"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
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
data "aws_ssm_parameter" "tailscale_client_id" {
  provider = aws.london
  name     = "/tailscale/oauth/client_id"
}

data "aws_ssm_parameter" "tailscale_client_secret" {
  provider = aws.london
  name     = "/tailscale/oauth/client_secret"
}

provider "tailscale" {
  oauth_client_id     = data.aws_ssm_parameter.tailscale_client_id.value
  oauth_client_secret = data.aws_ssm_parameter.tailscale_client_secret.value
}

# Generate Tailscale auth key
resource "tailscale_tailnet_key" "exit_node_key" {
  reusable      = false
  ephemeral     = true  # Device will be removed when key expires/deleted
  preauthorized = true
  expiry        = 86400 # 24 hours - long enough for deployment
  description   = "Auto-generated key for ${local.instance_name}"
  tags          = ["tag:awslightsail"]
}

# Wait for device to register, then enable as exit node
data "tailscale_device" "exit_node" {
  hostname   = local.instance_name  # Use hostname which matches exactly
  wait_for   = "60s"
  depends_on = [aws_lightsail_instance.tailscale_exit_node]
}

# Auto-approve and configure exit node
resource "tailscale_device_authorization" "exit_node" {
  device_id  = data.tailscale_device.exit_node.id
  authorized = true
}

resource "tailscale_device_subnet_routes" "exit_node" {
  device_id = data.tailscale_device.exit_node.id
  routes    = ["0.0.0.0/0", "::/0"]
  depends_on = [tailscale_device_authorization.exit_node]
}

# Manage device lifecycle - will delete device when destroyed
resource "tailscale_device_tags" "exit_node" {
  device_id = data.tailscale_device.exit_node.id
  tags      = ["tag:awslightsail"]
}

# User data script for Lightsail instance
locals {
  user_data = templatefile("${path.module}/scripts/user-data.sh", {
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

# Get current public IP for SSH access restriction
data "http" "current_ip" {
  url = "https://ipv4.icanhazip.com"
}

locals {
  current_ip = chomp(data.http.current_ip.response_body)
}

# Restrict SSH to current IP only, block HTTP entirely
resource "aws_lightsail_instance_public_ports" "tailscale_exit_node_ports" {
  instance_name = aws_lightsail_instance.tailscale_exit_node.name

  port_info {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidrs     = ["${local.current_ip}/32"]  # Only current IP
  }
  
  # No HTTP port configured = blocked
  # Tailscale connects outbound only
}