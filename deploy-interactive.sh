#!/bin/bash

set -e

echo "=== Tailscale Exit Node Interactive Deployment ==="
echo

# Prompt for Tailscale auth key
read -s -p "Enter Tailscale auth key: " TAILSCALE_AUTH_KEY
echo
echo

# Get enabled regions with descriptions
echo "Fetching enabled regions..."
REGION_DATA=$(aws account list-regions \
  --query "Regions[?RegionOptStatus=='ENABLED' || RegionOptStatus=='ENABLED_BY_DEFAULT'].[RegionName,RegionName]" \
  --output text 2>/dev/null | sort || \
  aws ec2 describe-regions \
  --query "Regions[?OptInStatus=='opt-in-not-required' || OptInStatus=='opted-in'].RegionName" \
  --output text | tr '\t' '\n' | sort | awk '{print $1 "\t" $1}')

if [ -z "$REGION_DATA" ]; then
    echo "❌ No enabled regions found"
    exit 1
fi

echo "Available regions:"
i=1
while IFS=$'\t' read -r region _; do
    case $region in
        us-east-1) DESC="N. Virginia" ;;
        us-east-2) DESC="Ohio" ;;
        us-west-1) DESC="N. California" ;;
        us-west-2) DESC="Oregon" ;;
        af-south-1) DESC="Cape Town" ;;
        ap-east-1) DESC="Hong Kong" ;;
        ap-south-1) DESC="Mumbai" ;;
        ap-south-2) DESC="Hyderabad" ;;
        ap-southeast-1) DESC="Singapore" ;;
        ap-southeast-2) DESC="Sydney" ;;
        ap-southeast-3) DESC="Jakarta" ;;
        ap-southeast-4) DESC="Melbourne" ;;
        ap-northeast-1) DESC="Tokyo" ;;
        ap-northeast-2) DESC="Seoul" ;;
        ap-northeast-3) DESC="Osaka" ;;
        ca-central-1) DESC="Canada Central" ;;
        ca-west-1) DESC="Canada West" ;;
        eu-central-1) DESC="Frankfurt" ;;
        eu-central-2) DESC="Zurich" ;;
        eu-west-1) DESC="Ireland" ;;
        eu-west-2) DESC="London" ;;
        eu-west-3) DESC="Paris" ;;
        eu-north-1) DESC="Stockholm" ;;
        eu-south-1) DESC="Milan" ;;
        eu-south-2) DESC="Spain" ;;
        il-central-1) DESC="Tel Aviv" ;;
        me-central-1) DESC="UAE" ;;
        me-south-1) DESC="Bahrain" ;;
        sa-east-1) DESC="São Paulo" ;;
        us-gov-east-1) DESC="AWS GovCloud East" ;;
        us-gov-west-1) DESC="AWS GovCloud West" ;;
        *) DESC="$region" ;;
    esac
    echo "$i) $region ($DESC)"
    ((i++))
done <<< "$REGION_DATA"
echo
echo "Note: If regions are missing, enable them in your AWS account"
echo

REGION_COUNT=$(echo "$REGION_DATA" | wc -l)
read -p "Select region (1-$REGION_COUNT): " REGION_CHOICE

if [[ ! "$REGION_CHOICE" =~ ^[0-9]+$ ]] || [ "$REGION_CHOICE" -lt 1 ] || [ "$REGION_CHOICE" -gt $REGION_COUNT ]; then
    echo "Invalid choice"
    exit 1
fi

REGION=$(echo "$REGION_DATA" | sed -n "${REGION_CHOICE}p" | cut -f1)

echo "Selected region: $REGION"
echo

# Get latest ARM64 Amazon Linux 2023 AMI
echo "Fetching latest ARM64 AMI for $REGION..."
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters \
        "Name=name,Values=al2023-ami-*-arm64" \
        "Name=state,Values=available" \
        "Name=architecture,Values=arm64" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text \
    --region "$REGION")

if [ "$AMI_ID" = "None" ] || [ -z "$AMI_ID" ]; then
    echo "❌ Failed to fetch AMI ID for $REGION"
    exit 1
fi

echo "Using AMI: $AMI_ID"
echo

# Use original template with AMI parameter

STACK_NAME="tailscale-exit-node-$REGION"

echo "Deploying stack: $STACK_NAME"
aws cloudformation deploy \
    --template-file "tailscale-exit-node.yaml" \
    --stack-name "$STACK_NAME" \
    --parameter-overrides \
        TailscaleAuthKey="$TAILSCALE_AUTH_KEY" \
        InstanceType="t4g.nano" \
        AMIId="$AMI_ID" \
    --capabilities CAPABILITY_IAM \
    --region "$REGION" \
    --no-fail-on-empty-changeset

if [ $? -eq 0 ]; then
    echo "✅ Successfully deployed to $REGION"
    
    # Get the public IP
    PUBLIC_IP=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`PublicIP`].OutputValue' \
        --output text)
    
    echo "   Instance: ts-$REGION"
    echo "   Public IP: $PUBLIC_IP"
else
    echo "❌ Failed to deploy to $REGION"
fi

