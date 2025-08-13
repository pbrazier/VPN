# Terraform Tailscale Exit Node Deployment

Fully automated Terraform deployment for Tailscale exit nodes on AWS Lightsail using OAuth authentication.

## Prerequisites

- **AWS CLI**: [Install](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and configure:
  ```bash
  aws configure
  # Enter your AWS Access Key ID, Secret, and region
  ```

- **Terraform**: [Install](https://developer.hashicorp.com/terraform/install) version 1.0+:
  ```bash
  # macOS
  brew install terraform
  
  # Or download from: https://developer.hashicorp.com/terraform/install
  ```
- **Tailscale OAuth Setup** (one-time):

**Create Tag**: In [Tailscale Admin Console](https://login.tailscale.com/admin/settings/acls)
- Go to Settings → Access Controls → Tags
- Create tag: `awslightsail`
- Set yourself as tag owner
- Note: "Terraform-managed AWS Lightsail exit nodes"

**Create OAuth Client**: In [Tailscale Admin Console](https://login.tailscale.com/admin/settings/oauth)
- Go to Settings → OAuth clients
- Click "Generate OAuth client"
- Description: "AwsLightsail"
- Required scopes:
  - **Devices**:
    - **Core** → Write ✓
    - **Routes** → Write ✓
    - **Device Invites** → Write ✓
  - **Keys**:
    - **Auth Keys** → Write ✓
- Tags: Select `tag:awslightsail`
- Copy both **Client ID** and **Client Secret** (you'll need both for OAuth authentication)

## Quick Start

1. **One command**: `./deploy.sh`
2. **Done!** Exit node automatically enabled and ready to use

The script handles everything: credential setup, region selection, deployment, and exit node enablement.

## Deployment

**Automated (Recommended):**
```bash
# Deploy to any region with interactive menu
./deploy.sh

# Manage multiple regions
./manage.sh

# Clean up current region
./cleanup.sh
```

The script automatically:
- Sets up S3 backend with state locking (first run only)
- Prompts for Tailscale OAuth credentials (first run only)
- Shows interactive region menu (12 regions available)
- Creates workspace for each region
- Deploys exit node with auto-generated name (`ts-virginia`, `ts-london`, etc.)
- Enables exit node routing with Tailscale provider

**That's it!** The exit node is automatically:
- Registered with your tailnet
- Enabled as an exit node
- Ready to route traffic

## Features

- **Fully Automated**: No manual auth key generation required
- **OAuth Integration**: Uses Tailscale provider for secure key management
- **Cost Optimized**: ~$3.50/month per region using Lightsail nano instances
- **Multi-Region Management**: Independent workspace per region
- **Auto-configured**: Exit node ready immediately after deployment
- **Secure State Management**: S3 backend with DynamoDB locking and encryption
- **One-Command Setup**: Automatically configures backend infrastructure

**Available Regions:**
`virginia`, `ohio`, `oregon`, `ireland`, `london`, `paris`, `frankfurt`, `singapore`, `sydney`, `tokyo`, `mumbai`, `canada`

**Multi-Region Management:**
- Each region uses its own Terraform workspace
- Deploy/destroy regions independently
- Use `./manage.sh` to switch between regions or view all deployments
- All workspaces share the same S3 backend for centralized state management

## Backend Infrastructure

The deployment automatically creates:
- **S3 Bucket**: Encrypted storage for Terraform state files
- **DynamoDB Table**: State locking to prevent concurrent modifications
- **Versioning**: Point-in-time recovery for state files
- **Security**: Private bucket with encryption at rest

**Backend Components:**
- `backend-setup/` - Terraform configuration for backend infrastructure
- `.backend-config` - Generated configuration file (git-ignored)
- State files stored as: `s3://bucket/tailscale-exit-nodes/terraform.tfstate`

## Cost

- **Monthly**: ~$3.50 per region (same as bash deployment)
- **Includes**: Instance + IPv4 + 1TB bandwidth + 20GB SSD
- **Backend**: ~$0.02/month (S3 + DynamoDB for state management)



---

## Manual Deployment

For advanced users who prefer manual control:

**Backend Management:**
```bash
# Backend is automatically set up on first deployment
# To manually set up backend infrastructure:
cd backend-setup
terraform init && terraform apply
```

**Credential Management:**
```bash
# Store credentials manually (optional - deploy.sh does this automatically)
./setup-credentials.sh
```

**Deploy:**
```bash
# Deploy to specific region
terraform init
terraform apply -var="region=london"

# Multiple regions (manual workspaces)
terraform workspace new london
terraform apply -var="region=london"

# Destroy deployment
terraform destroy
```

## Advantages over Bash Scripts

- **State Management**: Terraform tracks infrastructure state in encrypted S3
- **State Locking**: DynamoDB prevents concurrent modifications
- **OAuth Security**: No manual key handling or expiration concerns
- **Secure Credential Storage**: OAuth credentials stored in AWS SSM Parameter Store
- **Backup & Recovery**: Versioned state files with point-in-time recovery
- **Idempotent**: Safe to re-run, only changes what's needed
- **Multi-Region**: Easy workspace management for multiple deployments
- **Version Control**: Infrastructure changes tracked in git
- **Enterprise Ready**: Remote state, locking, and team collaboration support