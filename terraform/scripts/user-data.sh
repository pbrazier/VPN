#!/bin/bash
set -e

# Update system
yum update -y

# Set hostname
hostnamectl set-hostname ${instance_name}

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf
sysctl -p

# Start Tailscale and authenticate
tailscale up --authkey=${auth_key} --advertise-exit-node --accept-routes

echo "Tailscale exit node setup complete"