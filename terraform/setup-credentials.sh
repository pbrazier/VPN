#!/bin/bash
set -e

echo "Setting up Tailscale OAuth credentials in AWS SSM Parameter Store..."

# Check if credentials are already stored
if aws ssm get-parameter --name "/tailscale/oauth/api_key" --region "${AWS_DEFAULT_REGION:-us-east-1}" >/dev/null 2>&1; then
    echo "Credentials already exist in SSM. Use 'terraform apply -target=module.tailscale_credentials' to update."
    exit 0
fi

# Prompt for credentials
read -s -p "Enter Tailscale OAuth API Key: " TAILSCALE_API_KEY
echo
read -p "Enter Tailscale Tailnet name: " TAILSCALE_TAILNET

# Store credentials using Terraform
terraform apply -target=module.tailscale_credentials \
    -var="tailscale_api_key=$TAILSCALE_API_KEY" \
    -var="tailscale_tailnet=$TAILSCALE_TAILNET"

echo "Credentials stored successfully in SSM Parameter Store"
echo "You can now run 'terraform apply' to deploy exit nodes"