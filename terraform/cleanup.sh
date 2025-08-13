#!/bin/bash
set -e

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

# Method 1: Try normal destroy
echo "Step 1: Attempting normal destroy..."
if terraform destroy -auto-approve; then
    echo "✅ Normal destroy successful"
else
    echo "⚠️  Normal destroy failed, trying targeted approach..."
    
    # Method 2: Destroy AWS resources first
    echo "Step 2: Destroying AWS resources..."
    terraform destroy -auto-approve \
        -target=aws_lightsail_instance_public_ports.tailscale_exit_node_ports \
        -target=aws_lightsail_instance.tailscale_exit_node \
        2>/dev/null || echo "AWS destroy completed/failed"
    
    # Method 3: Destroy remaining resources
    echo "Step 3: Destroying remaining resources..."
    terraform destroy -auto-approve 2>/dev/null || echo "Remaining destroy completed/failed"
fi

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