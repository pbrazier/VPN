#!/bin/bash
set -e

# Available regions
REGIONS=("virginia" "ohio" "oregon" "ireland" "london" "paris" "frankfurt" "singapore" "sydney" "tokyo" "mumbai" "canada")

echo "Tailscale Exit Node Deployment"
echo "=============================="

# Check if credentials exist
if ! aws ssm get-parameter --name "/tailscale/oauth/client_secret" --region "eu-west-2" >/dev/null 2>&1; then
    echo "⚠️  Tailscale credentials not found. Setting up first..."
    ./setup-credentials.sh
    echo
fi

# Region selection
echo "Select deployment region:"
for i in "${!REGIONS[@]}"; do
    printf "%2d) %s\n" $((i+1)) "${REGIONS[$i]}"
done

while true; do
    read -p "Enter choice (1-${#REGIONS[@]}): " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#REGIONS[@]}" ]; then
        REGION="${REGIONS[$((choice-1))]}"
        break
    fi
    echo "Invalid choice. Please enter 1-${#REGIONS[@]}"
done

echo
echo "Deploying to: $REGION (ts-$REGION)"
echo

# Initialize if needed
if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

# Create/select workspace for region
echo "Setting up workspace: $REGION"
terraform workspace select "$REGION" 2>/dev/null || terraform workspace new "$REGION"

# Deploy
terraform apply -auto-approve -var="region=$REGION"