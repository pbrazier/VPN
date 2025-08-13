#!/bin/bash
set -e

echo "Setting up Tailscale OAuth credentials in AWS SSM Parameter Store..."

# Check if credentials are already stored in London region
if aws ssm get-parameter --name "/tailscale/oauth/client_secret" --region "eu-west-2" >/dev/null 2>&1; then
    echo "Credentials already exist in SSM. Use 'terraform apply -target=module.tailscale_credentials' to update."
    exit 0
fi

# Prompt for credentials first
read -s -p "Enter Tailscale OAuth Client Secret: " TAILSCALE_CLIENT_SECRET
echo

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

# Store credentials using AWS CLI directly
aws ssm put-parameter \
    --region "eu-west-2" \
    --name "/tailscale/oauth/client_secret" \
    --value "$TAILSCALE_CLIENT_SECRET" \
    --type "SecureString" \
    --overwrite

echo "Credentials stored successfully in SSM Parameter Store (London region)"
echo "You can now run 'terraform apply' to deploy exit nodes to any region"