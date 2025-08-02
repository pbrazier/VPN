#!/bin/bash

set -e

echo "=== Tailscale Exit Node Lightsail Deployment ==="
echo

# Prompt for Tailscale auth key
read -s -p "Enter Tailscale auth key: " TAILSCALE_AUTH_KEY
echo
echo

# Validate auth key format
if [[ ! "$TAILSCALE_AUTH_KEY" =~ ^tskey-auth- ]]; then
    echo "❌ Invalid Tailscale auth key format. Must start with 'tskey-auth-'"
    exit 1
fi

# Get available regions for Lightsail
echo "Fetching available Lightsail regions..."
REGIONS=($(aws lightsail get-regions --query "regions[].name" --output text | tr '\t' '\n' | sort))

if [ ${#REGIONS[@]} -eq 0 ]; then
    echo "❌ No Lightsail regions found"
    exit 1
fi

echo "Available regions:"
for i in "${!REGIONS[@]}"; do
    REGION_NAME="${REGIONS[i]}"
    case $REGION_NAME in
        us-east-1) DESC="N. Virginia" ;;
        us-east-2) DESC="Ohio" ;;
        us-west-2) DESC="Oregon" ;;
        eu-west-1) DESC="Ireland" ;;
        eu-west-2) DESC="London" ;;
        eu-west-3) DESC="Paris" ;;
        eu-central-1) DESC="Frankfurt" ;;
        eu-north-1) DESC="Stockholm" ;;
        ap-southeast-1) DESC="Singapore" ;;
        ap-southeast-2) DESC="Sydney" ;;
        ap-southeast-3) DESC="Jakarta" ;;
        ap-northeast-1) DESC="Tokyo" ;;
        ap-northeast-2) DESC="Seoul" ;;
        ap-south-1) DESC="Mumbai" ;;
        ca-central-1) DESC="Canada Central" ;;
        *) DESC="$REGION_NAME" ;;
    esac
    echo "$((i+1))) $REGION_NAME ($DESC)"
done
echo
echo "Note: If regions are missing, they may not support Lightsail"
echo

REGION_COUNT=${#REGIONS[@]}
read -p "Select region (1-$REGION_COUNT): " REGION_CHOICE

if [[ ! "$REGION_CHOICE" =~ ^[0-9]+$ ]] || [ "$REGION_CHOICE" -lt 1 ] || [ "$REGION_CHOICE" -gt $REGION_COUNT ]; then
    echo "Invalid choice"
    exit 1
fi

REGION="${REGIONS[$((REGION_CHOICE-1))]}"
echo "Selected region: $REGION"
echo

# Generate friendly name for instance (auto-handles new regions)
case $REGION in
    us-east-1) FRIENDLY_NAME="virginia" ;;
    us-east-2) FRIENDLY_NAME="ohio" ;;
    us-west-2) FRIENDLY_NAME="oregon" ;;
    eu-west-1) FRIENDLY_NAME="ireland" ;;
    eu-west-2) FRIENDLY_NAME="london" ;;
    eu-west-3) FRIENDLY_NAME="paris" ;;
    eu-central-1) FRIENDLY_NAME="frankfurt" ;;
    eu-north-1) FRIENDLY_NAME="stockholm" ;;
    ap-southeast-1) FRIENDLY_NAME="singapore" ;;
    ap-southeast-2) FRIENDLY_NAME="sydney" ;;
    ap-southeast-3) FRIENDLY_NAME="jakarta" ;;
    ap-northeast-1) FRIENDLY_NAME="tokyo" ;;
    ap-northeast-2) FRIENDLY_NAME="seoul" ;;
    ap-south-1) FRIENDLY_NAME="mumbai" ;;
    ca-central-1) FRIENDLY_NAME="canada" ;;
    *) FRIENDLY_NAME=$(echo "$REGION" | sed 's/-//g') ;;  # Auto-generate for new regions
esac

INSTANCE_NAME="ts-$FRIENDLY_NAME"

# Create user data script
USER_DATA=$(cat << 'EOF'
#!/bin/bash
set -e

# Update system
yum update -y

# Set hostname with friendly name
hostnamectl set-hostname INSTANCE_NAME_PLACEHOLDER

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf
sysctl -p

# Start Tailscale and authenticate
tailscale up --authkey=TAILSCALE_AUTH_KEY_PLACEHOLDER --advertise-exit-node --accept-routes

# Setup complete
echo "Tailscale exit node setup complete"
EOF
)

# Replace placeholders in user data
USER_DATA="${USER_DATA//INSTANCE_NAME_PLACEHOLDER/$INSTANCE_NAME}"
USER_DATA="${USER_DATA//TAILSCALE_AUTH_KEY_PLACEHOLDER/$TAILSCALE_AUTH_KEY}"

echo "Creating Lightsail instance: $INSTANCE_NAME"

# Create Lightsail instance
aws lightsail create-instances \
  --instance-names "$INSTANCE_NAME" \
  --availability-zone "${REGION}a" \
  --blueprint-id "amazon_linux_2023" \
  --bundle-id "nano_3_0" \
  --user-data "$USER_DATA" \
  --tags "key=project,value=tailscale" \
  --region "$REGION"

if [ $? -eq 0 ]; then
    echo "✅ Successfully created Lightsail instance: $INSTANCE_NAME"
    echo
    
    # Wait for instance to be running
    echo "Waiting for instance to be running..."
    while true; do
        STATE=$(aws lightsail get-instance-state \
            --instance-name "$INSTANCE_NAME" \
            --region "$REGION" \
            --query 'state.name' \
            --output text 2>/dev/null || echo "pending")
        
        if [ "$STATE" = "running" ]; then
            break
        elif [ "$STATE" = "stopped" ] || [ "$STATE" = "stopping" ]; then
            echo "❌ Instance failed to start (state: $STATE)"
            exit 1
        fi
        
        echo "Instance state: $STATE (waiting...)"
        sleep 10
    done
    
    # Get instance details
    INSTANCE_INFO=$(aws lightsail get-instance \
        --instance-name "$INSTANCE_NAME" \
        --region "$REGION" \
        --query 'instance.{PublicIp:publicIpAddress,PrivateIp:privateIpAddress,State:state.name}' \
        --output json)
    
    PUBLIC_IP=$(echo "$INSTANCE_INFO" | jq -r '.PublicIp // "pending"')
    STATE=$(echo "$INSTANCE_INFO" | jq -r '.State')
    
    echo "   Instance: $INSTANCE_NAME"
    echo "   State: $STATE"
    echo "   Public IP: $PUBLIC_IP"
    echo
    echo "Configuring firewall (removing SSH/HTTP access)..."
    
    # Close SSH port 22 (keep browser SSH only)
    aws lightsail close-instance-public-ports \
      --instance-name "$INSTANCE_NAME" \
      --port-info fromPort=22,toPort=22,protocol=TCP \
      --region "$REGION" 2>/dev/null || echo "SSH port already closed"
    
    # Close HTTP port 80
    aws lightsail close-instance-public-ports \
      --instance-name "$INSTANCE_NAME" \
      --port-info fromPort=80,toPort=80,protocol=TCP \
      --region "$REGION" 2>/dev/null || echo "HTTP port already closed"
    
    # Close HTTPS port 443 if open
    aws lightsail close-instance-public-ports \
      --instance-name "$INSTANCE_NAME" \
      --port-info fromPort=443,toPort=443,protocol=TCP \
      --region "$REGION" 2>/dev/null || echo "HTTPS port already closed"
    
    echo "✅ Firewall configured - only Lightsail browser SSH access available"
    echo "Instance is starting up. Tailscale setup will complete in 2-3 minutes."
    echo "Check Tailscale admin console for the new exit node."
else
    echo "❌ Failed to create Lightsail instance"
    exit 1
fi