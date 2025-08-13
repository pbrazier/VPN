resource "aws_ssm_parameter" "tailscale_api_key" {
  name  = "/tailscale/oauth/api_key"
  type  = "SecureString"
  value = var.tailscale_api_key

  tags = {
    project = "tailscale"
  }
}

resource "aws_ssm_parameter" "tailscale_tailnet" {
  name  = "/tailscale/oauth/tailnet"
  type  = "String"
  value = var.tailscale_tailnet

  tags = {
    project = "tailscale"
  }
}