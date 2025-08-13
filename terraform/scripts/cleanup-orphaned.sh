#!/bin/bash
set -e

export AWS_PROFILE=PBCT-Development

echo "Orphaned Resource Cleanup"
echo "========================"
echo "This script finds and removes AWS resources that are no longer managed by Terraform"
echo

# Check for orphaned Lightsail instances with ts- prefix
echo "Checking for orphaned Lightsail instances..."

REGIONS=("us-east-1" "us-east-2" "us-west-2" "eu-west-1" "eu-west-2" "eu-west-3" "eu-central-1" "ap-southeast-1" "ap-southeast-2" "ap-northeast-1" "ap-south-1" "ca-central-1")
REGION_NAMES=("virginia" "ohio" "oregon" "ireland" "london" "paris" "frankfurt" "singapore" "sydney" "tokyo" "mumbai" "canada")

FOUND_INSTANCES=()

for i in "${!REGIONS[@]}"; do
    region="${REGIONS[$i]}"
    region_name="${REGION_NAMES[$i]}"
    
    echo "Checking $region_name ($region)..."
    
    instances=$(aws lightsail get-instances --region "$region" --query "instances[?starts_with(name, 'ts-')].name" --output text 2>/dev/null || echo "")
    
    if [ -n "$instances" ]; then
        for instance in $instances; do
            FOUND_INSTANCES+=("$instance:$region:$region_name")
            echo "  Found: $instance"
        done
    fi
done

if [ ${#FOUND_INSTANCES[@]} -eq 0 ]; then
    echo "✅ No orphaned Lightsail instances found"
    exit 0
fi

echo
echo "Found ${#FOUND_INSTANCES[@]} orphaned instance(s):"
for i in "${!FOUND_INSTANCES[@]}"; do
    IFS=':' read -r instance region region_name <<< "${FOUND_INSTANCES[$i]}"
    printf "%2d) %s (%s - %s)\n" $((i+1)) "$instance" "$region_name" "$region"
done

echo
read -p "Delete ALL orphaned instances? (type 'yes' to confirm): " confirm
if [ "$confirm" != "yes" ]; then
    echo "❌ Cancelled"
    exit 0
fi

echo
echo "🔥 Deleting orphaned instances..."
for instance_info in "${FOUND_INSTANCES[@]}"; do
    IFS=':' read -r instance region region_name <<< "$instance_info"
    
    echo "Deleting $instance in $region_name..."
    
    # Delete the instance
    aws lightsail delete-instance --region "$region" --instance-name "$instance"
    
    echo "✅ $instance deleted"
done

echo
echo "🎉 All orphaned instances cleaned up!"
echo
echo "Note: Tailscale devices may still exist in your tailnet."
echo "Check https://login.tailscale.com/admin/machines and remove manually if needed."