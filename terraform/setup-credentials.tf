# Separate deployment for storing Tailscale OAuth credentials
# Deploy this first: terraform apply -target=module.tailscale_credentials

module "tailscale_credentials" {
  source = "./modules/tailscale-credentials"
  
  tailscale_api_key = var.tailscale_api_key
  tailscale_tailnet = var.tailscale_tailnet
}

# Data sources to read credentials from SSM
data "aws_ssm_parameter" "tailscale_api_key" {
  name       = "/tailscale/oauth/api_key"
  depends_on = [module.tailscale_credentials]
}

data "aws_ssm_parameter" "tailscale_tailnet" {
  name       = "/tailscale/oauth/tailnet"
  depends_on = [module.tailscale_credentials]
}