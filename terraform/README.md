# Terraform Tailscale Exit Node Deployment

Fully automated Terraform deployment for Tailscale exit nodes on AWS Lightsail using OAuth authentication.

## Features

- **Fully Automated**: No manual auth key generation required
- **OAuth Integration**: Uses Tailscale provider for secure key management
- **Cost Optimized**: ~$3.50/month per region using Lightsail nano instances
- **Infrastructure as Code**: Version controlled, repeatable deployments
- **Auto-configured**: Exit node ready immediately after deployment

## Prerequisites

1. **Create Tailscale Tag**: In [Tailscale Admin Console](https://login.tailscale.com/admin/settings/acls)
   - Go to Settings → Access Controls → Tags
   - Create tag: `AwsLightsail`
   - Set yourself as tag owner
   - Note: "Terraform-managed AWS Lightsail exit nodes"

2. **Tailscale OAuth Client**: Create in [Tailscale Admin Console](https://login.tailscale.com/admin/settings/oauth)
   - Go to Settings → OAuth clients
   - Click "Generate OAuth client"
   - Description: "AwsLightsail"
   - Required scopes:
     - **Devices** → Write ✓
     - **Auth Keys** → Write ✓
     - **Device Invites** → Write ✓
   - Tags: Select `tag:awslightsail`
   - Copy Client ID and Client Secret

3. **AWS CLI**: Configured with Lightsail permissions

4. **Terraform**: Version 1.0+ installed

## Setup

1. **Store Tailscale OAuth credentials** (one-time setup):
   ```bash
   ./setup-credentials.sh
   ```
   This stores your OAuth credentials securely in AWS SSM Parameter Store.

2. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your preferred region and instance name
   ```

3. **Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Configure exit node** (required):
   - Go to [Tailscale Admin Console](https://login.tailscale.com/admin/machines)
   - Find your new node and enable "Use as exit node"
   - Disable key expiry

## Usage

```bash
# Deploy to Virginia
terraform apply -var="aws_region=us-east-1" -var="instance_name=ts-virginia"

# Deploy to multiple regions (separate state files)
terraform workspace new oregon
terraform apply -var="aws_region=us-west-2" -var="instance_name=ts-oregon"

# Destroy deployment
terraform destroy
```

## Advantages over Bash Scripts

- **State Management**: Terraform tracks infrastructure state
- **OAuth Security**: No manual key handling or expiration concerns
- **Secure Credential Storage**: OAuth credentials stored in AWS SSM (free)
- **Idempotent**: Safe to re-run, only changes what's needed
- **Multi-Region**: Easy workspace management for multiple deployments
- **Version Control**: Infrastructure changes tracked in git
- **No Environment Variables**: Credentials managed by AWS, not shell

## Cost

- **Monthly**: ~$3.50 per region (same as bash deployment)
- **Includes**: Instance + IPv4 + 1TB bandwidth + 20GB SSD

## Security

- OAuth eliminates manual auth key management
- Keys auto-expire after 1 hour (sufficient for deployment)
- Automatic firewall configuration
- Browser SSH access only