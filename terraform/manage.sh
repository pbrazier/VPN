#!/bin/bash
set -e

echo "Tailscale Exit Node Management"
echo "=============================="

if [ ! -d ".terraform" ]; then
    echo "No Terraform found. Run ./deploy.sh first."
    exit 1
fi

# Show current workspace and list all
echo "Current workspace: $(terraform workspace show)"
echo
echo "All deployments:"
terraform workspace list

echo
echo "Management options:"
echo "1) Switch to different region"
echo "2) Show deployment details"
echo "3) List all deployments"
echo "4) Delete specific region"

read -p "Choose option (1-4): " choice

case $choice in
    1)
        echo
        echo "Available workspaces:"
        terraform workspace list | grep -v "^*" | sed 's/^  //'
        read -p "Enter workspace name: " workspace
        terraform workspace select "$workspace"
        echo "Switched to: $workspace"
        terraform output 2>/dev/null || echo "No resources in this workspace"
        ;;
    2)
        echo
        echo "Current deployment ($(terraform workspace show)):"
        terraform output 2>/dev/null || echo "No resources deployed"
        ;;
    3)
        echo
        for workspace in $(terraform workspace list | sed 's/^[* ] //'); do
            echo "=== $workspace ==="
            terraform workspace select "$workspace" >/dev/null
            terraform output 2>/dev/null || echo "No resources"
            echo
        done
        ;;
    4)
        echo
        echo "Available deployments:"
        terraform workspace list | grep -v "^*" | sed 's/^  //'
        read -p "Enter workspace to delete: " workspace
        if [ "$workspace" = "default" ]; then
            echo "Cannot delete default workspace"
            exit 1
        fi
        terraform workspace select "$workspace"
        echo "Destroying $workspace..."
        terraform destroy
        terraform workspace select default
        terraform workspace delete "$workspace"
        echo "Workspace $workspace deleted"
        ;;
    *)
        echo "Invalid option"
        ;;
esac