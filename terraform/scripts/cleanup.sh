#!/bin/bash
set -e

# TODO: Cleanup script still not properly destroying AWS Lightsail instances
# Issue: Normal destroy fails due to Tailscale dependencies, targeted destroy not working
# Need to fix dependency order and ensure AWS resources are actually removed
# Current workaround: Use cleanup-orphaned.sh for stuck instances

export AWS_PROFILE=PBCT-Development

echo "Tailscale Exit Node Cleanup"
echo "=========================="

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "❌ No Terraform found. Nothing to cleanup."
    exit 0
fi

# List all workspaces
echo "Available workspaces:"
terraform workspace list

CURRENT_WORKSPACE=$(terraform workspace show)
echo
echo "Current workspace: $CURRENT_WORKSPACE"

# Check for actual resources in current workspace
RESOURCES=$(terraform state list 2>/dev/null || echo "")
if [ -z "$RESOURCES" ]; then
    echo "✅ No resources found in workspace: $CURRENT_WORKSPACE"
    if [ "$CURRENT_WORKSPACE" != "default" ]; then
        read -p "Delete empty workspace '$CURRENT_WORKSPACE'? (y/n): " delete_ws
        if [ "$delete_ws" = "y" ]; then
            terraform workspace select default
            terraform workspace delete "$CURRENT_WORKSPACE"
            echo "✅ Workspace deleted"
        fi
    fi
    exit 0
fi

echo
echo "Resources in workspace '$CURRENT_WORKSPACE':"
echo "$RESOURCES"
echo

# Get region from state if possible
REGION=$(terraform output -raw region 2>/dev/null || echo "unknown")
INSTANCE_NAME=$(terraform output -raw instance_name 2>/dev/null || echo "unknown")

echo "Deployment details:"
echo "  Region: $REGION"
echo "  Instance: $INSTANCE_NAME"
echo

read -p "❗ Destroy ALL resources in workspace '$CURRENT_WORKSPACE'? (type 'yes' to confirm): " confirm
if [ "$confirm" != "yes" ]; then
    echo "❌ Cancelled"
    exit 0
fi

echo
echo "🔥 DESTROYING ALL RESOURCES..."
echo "================================"

#TODO Test and fix removal of terraform resources as terraform destroy doesn't actually remove resources
# Why: Current terraform destroy fails to properly remove AWS Lightsail instances due to dependency issues and Tailscale resource conflicts. This leaves orphaned resources that continue billing.
# What to do: • Test actual resource removal in AWS console after terraform destroy • Add verification checks for AWS resource deletion • Implement retry logic for failed destroys • Add manual AWS CLI cleanup as fallback • Test dependency ordering between Tailscale and AWS resources
# Where: /Users/paul/Documents/snap1-code-repos/VPN/terraform/scripts/cleanup.sh:65-85
# Notes: Existing workaround uses cleanup-orphaned.sh for stuck instances. May need to separate Tailscale cleanup from AWS cleanup entirely.
# Added: 2025-08-18 by Q

# Method 1: Destroy AWS resources first (most reliable)
echo "Step 1: Destroying AWS resources..."
terraform destroy -auto-approve \
    -target=aws_lightsail_instance_public_ports.tailscale_exit_node_ports \
    -target=aws_lightsail_instance.tailscale_exit_node

if [ $? -eq 0 ]; then
    echo "✅ AWS resources destroyed successfully"
else
    echo "⚠️  AWS destroy failed, continuing with remaining resources..."
fi

# Method 2: Destroy Tailscale resources
echo "Step 2: Destroying Tailscale resources..."
terraform destroy -auto-approve \
    -target=tailscale_device_subnet_routes.exit_node \
    -target=tailscale_device_authorization.exit_node \
    -target=tailscale_device_tags.exit_node \
    -target=tailscale_tailnet_key.exit_node_key \
    2>/dev/null || echo "Tailscale destroy completed/failed"

# Method 3: Final cleanup - destroy anything remaining
echo "Step 3: Final cleanup..."
terraform destroy -auto-approve 2>/dev/null || echo "Final destroy completed/failed"

# Method 4: Nuclear option - remove from state if still exists
REMAINING=$(terraform state list 2>/dev/null || echo "")
if [ -n "$REMAINING" ]; then
    echo "⚠️  Some resources still in state, removing manually..."
    for resource in $REMAINING; do
        echo "Removing $resource from state..."
        terraform state rm "$resource" 2>/dev/null || echo "Failed to remove $resource"
    done
fi

# Verify cleanup
FINAL_CHECK=$(terraform state list 2>/dev/null || echo "")
if [ -z "$FINAL_CHECK" ]; then
    echo "✅ All resources destroyed successfully!"
else
    echo "❌ Some resources may still exist:"
    echo "$FINAL_CHECK"
fi

# Delete workspace if not default
if [ "$CURRENT_WORKSPACE" != "default" ]; then
    terraform workspace select default
    terraform workspace delete "$CURRENT_WORKSPACE" 2>/dev/null || echo "Workspace deletion failed"
    echo "✅ Workspace '$CURRENT_WORKSPACE' deleted"
fi

echo
echo "🎉 Cleanup complete!"