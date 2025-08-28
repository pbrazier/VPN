#!/bin/bash
set -e

# Available regions
REGIONS=("virginia" "ohio" "oregon" "ireland" "london" "paris" "frankfurt" "singapore" "sydney" "tokyo" "mumbai" "canada" "stockholm")

echo "Tailscale Exit Node Deployment"
echo "=============================="
echo

# =============================================================================
# COLLECT ALL USER INPUTS FIRST
# =============================================================================

# Check AWS authentication first
echo "🔐 Checking AWS authentication..."
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "❌ AWS authentication failed. Please run 'aws configure' or set up your AWS credentials."
    echo "   You can also set AWS_PROFILE environment variable if using profiles."
    exit 1
fi
echo "✅ AWS authentication verified"
echo

# Check if credentials exist and collect if needed
echo "🔑 Checking Tailscale OAuth credentials..."
NEED_CREDENTIALS=false
if ! aws ssm get-parameter --name "/tailscale/oauth/client_id" --region "eu-west-2" >/dev/null 2>&1 || \
   ! aws ssm get-parameter --name "/tailscale/oauth/client_secret" --region "eu-west-2" >/dev/null 2>&1; then
    echo "⚠️  Tailscale OAuth credentials required"
    NEED_CREDENTIALS=true
    
    # Collect credentials
    read -s -p "Enter Tailscale OAuth Client ID: " TAILSCALE_CLIENT_ID
    echo
    read -s -p "Enter Tailscale OAuth Client Secret: " TAILSCALE_CLIENT_SECRET
    echo
    echo
else
    echo "✅ Tailscale credentials found in Parameter Store"
fi
echo

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
echo "=============================================================================="
echo "Starting deployment to: $REGION (ts-$REGION)"
echo "=============================================================================="
echo

# =============================================================================
# EXECUTION PHASE - NO MORE USER INPUT REQUIRED
# =============================================================================

# Setup backend if needed
if [ ! -f ".backend-config" ]; then
    echo "⚙️  Setting up Terraform S3 backend..."
    cd modules/backend-setup
    
    echo "⚙️  Initializing backend Terraform..."
    terraform init
    
    terraform apply -auto-approve
    
    BUCKET_NAME=$(terraform output -raw bucket_name)
    TABLE_NAME=$(terraform output -raw dynamodb_table)
    
    cd ..
    
    # Create backend config file
    cat > .backend-config << EOF
bucket         = "$BUCKET_NAME"
key            = "tailscale-exit-nodes/terraform.tfstate"
region         = "eu-west-2"
encrypt        = true
dynamodb_table = "$TABLE_NAME"
EOF
    
    echo "✅ Backend setup complete!"
    echo
fi

# Store credentials if needed
if [ "$NEED_CREDENTIALS" = true ]; then
    echo "⚙️  Storing Tailscale OAuth credentials..."
    cd modules/credentials
    
    echo "⚙️  Initializing credentials Terraform..."
    terraform init
    
    terraform apply -auto-approve \
        -var="tailscale_client_id=$TAILSCALE_CLIENT_ID" \
        -var="tailscale_client_secret=$TAILSCALE_CLIENT_SECRET"
    
    cd ..
    echo "✅ Credentials stored successfully!"
    echo
fi

# Initialize main Terraform
echo "⚙️  Initializing main Terraform..."
terraform init -backend-config=.backend-config

# Create/select workspace for region
echo "⚙️  Setting up workspace: $REGION"
terraform workspace select "$REGION" 2>/dev/null || terraform workspace new "$REGION"

# Check for orphaned resources (manually deleted instances)
echo "🔍 Checking for orphaned resources..."
INSTANCE_IN_STATE=$(terraform state list | grep "aws_lightsail_instance.tailscale_exit_node" 2>/dev/null || echo "")
if [ -n "$INSTANCE_IN_STATE" ]; then
    INSTANCE_NAME="ts-$REGION"
    if ! aws lightsail get-instance --instance-name "$INSTANCE_NAME" >/dev/null 2>&1; then
        echo "⚠️  Found orphaned state for manually deleted instance '$INSTANCE_NAME'"
        echo "🔧 Cleaning up orphaned resources from state..."
        terraform state rm "aws_lightsail_instance.tailscale_exit_node" 2>/dev/null || true
        terraform state rm "aws_lightsail_instance_public_ports.tailscale_exit_node_ports" 2>/dev/null || true
        echo "✅ Orphaned resources cleaned up"
    fi
fi

# Create workspace-specific tfvars file to persist region setting
echo "⚙️  Creating workspace configuration..."
cat > terraform.tfvars << EOF
region = "$REGION"
EOF
echo "✅ Region '$REGION' saved to terraform.tfvars"

# Deploy
echo "⚙️  Deploying exit node..."
terraform apply -auto-approve

echo
echo "✅ Deployment complete! Exit node ts-$REGION is ready to use."