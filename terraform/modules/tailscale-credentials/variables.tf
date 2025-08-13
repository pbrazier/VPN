variable "tailscale_api_key" {
  description = "Tailscale OAuth API key"
  type        = string
  sensitive   = true
}

variable "tailscale_tailnet" {
  description = "Tailscale tailnet name"
  type        = string
}