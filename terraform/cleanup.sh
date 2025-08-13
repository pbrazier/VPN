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
terraform workspace list | grep -v "^\*" | sed 's/^  //'
echo
echo "Current workspace: $(terraform workspace show)"

# Show current deployment
if terraform show >/dev/null 2>&1; then
    echo
    echo "Current deployment details:"
    terraform output 2>/dev/null || echo "No outputs available"
fi

echo
read -p "Destroy current workspace ($(terraform workspace show))? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Cancelled"
    exit 0
fi

WORKSPACE=$(terraform workspace show)
echo "Destroying deployment in workspace: $WORKSPACE"
terraform destroy

# Switch back to default and delete workspace if not default
if [ "$WORKSPACE" != "default" ]; then
    terraform workspace select default
    terraform workspace delete "$WORKSPACE"
    echo "Workspace $WORKSPACE deleted"
fi