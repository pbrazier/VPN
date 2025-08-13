#!/bin/bash
set -e

echo "Tailscale Exit Node Cleanup"
echo "=========================="

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "No Terraform found. Run ./deploy.sh first."
    exit 1
fi

# List available workspaces (regions)
echo "Available deployments:"
terraform workspace list | grep -v "^\\*" | sed 's/^  //'
echo
echo "Current workspace: $(terraform workspace show)"

# Show current deployment
if terraform state list >/dev/null 2>&1 && [ "$(terraform state list | wc -l)" -gt 0 ]; then
    echo
    echo "Current deployment details:"
    terraform output 2>/dev/null || echo "No outputs available"
else
    echo "No resources found in current workspace"
fi

echo
read -p "Destroy current workspace ($(terraform workspace show))? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Cancelled"
    exit 0
fi

WORKSPACE=$(terraform workspace show)
echo "Destroying deployment in workspace: $WORKSPACE"

# First destroy AWS resources (these usually work)
echo "⚙️  Destroying AWS resources first..."
terraform destroy -auto-approve \
    -target=aws_lightsail_instance_public_ports.tailscale_exit_node_ports \
    -target=aws_lightsail_instance.tailscale_exit_node

# Then destroy remaining Tailscale resources
echo "⚙️  Destroying remaining Tailscale resources..."
terraform destroy -auto-approve

echo "✅ Resources destroyed successfully"

# Switch back to default and delete workspace if not default
if [ "$WORKSPACE" != "default" ]; then
    terraform workspace select default
    terraform workspace delete "$WORKSPACE"
    echo "✅ Workspace $WORKSPACE deleted"
fi

echo "✅ Cleanup complete!"