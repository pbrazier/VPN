#!/bin/bash
set -e

echo "Setting up Tailscale OAuth credentials in AWS SSM Parameter Store..."

# Check if credentials are already stored in London region
if aws ssm get-parameter --name "/tailscale/oauth/client_secret" --region "eu-west-2" >/dev/null 2>&1; then
    echo "Credentials already exist in SSM."
    read -p "Update with new Client Secret? (y/n): " update_choice
    if [ "$update_choice" != "y" ]; then
        echo "Keeping existing credentials."
        exit 0
    fi
fi

# Prompt for credentials
read -s -p "Enter Tailscale OAuth Client Secret: " TAILSCALE_CLIENT_SECRET
echo

# Navigate to credentials directory
cd credentials

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    echo "Initializing credentials Terraform..."
    terraform init
fi

echo "Storing credentials in AWS SSM Parameter Store (London region)..."

# Store credentials using Terraform
terraform apply -auto-approve -var="tailscale_client_secret=$TAILSCALE_CLIENT_SECRET"

echo "✅ Credentials stored successfully!"
cd ..