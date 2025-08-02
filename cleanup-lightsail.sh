#!/bin/bash

set -e

echo "=== Tailscale Exit Node Lightsail Cleanup ==="
echo

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

REGION_COUNT=${#REGIONS[@]}
read -p "Select region to remove (1-$REGION_COUNT): " REGION_CHOICE

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

echo "Removing Lightsail instance: $INSTANCE_NAME"
echo

# Check if instance exists
INSTANCE_EXISTS=$(aws lightsail get-instances \
    --query "instances[?name=='$INSTANCE_NAME'].name" \
    --output text \
    --region "$REGION" 2>/dev/null || echo "")

if [ -z "$INSTANCE_EXISTS" ]; then
    echo "❌ Instance $INSTANCE_NAME not found in region $REGION"
    exit 1
fi

# Delete the instance
aws lightsail delete-instance \
    --instance-name "$INSTANCE_NAME" \
    --region "$REGION"

if [ $? -eq 0 ]; then
    echo "✅ Deletion initiated for $INSTANCE_NAME"
    echo "Instance will be terminated shortly."
else
    echo "❌ Failed to delete instance $INSTANCE_NAME"
    exit 1
fi