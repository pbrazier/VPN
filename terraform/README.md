# Tailscale Exit Node - Terraform Implementation

**Production-ready, fully automated Terraform deployment** for Tailscale exit nodes on AWS Lightsail with enterprise-grade state management.

## Features

- **Fully Automated**: Complete end-to-end deployment with zero manual steps
- **Auto-Configured Exit Nodes**: Devices automatically enabled as exit nodes
- **OAuth Integration**: Secure Tailscale API authentication with credential management
- **Cost Optimized**: ~$3.50/month per region using Lightsail nano instances
- **Multi-Region Management**: Independent workspace per region with shared backend
- **Secure State Management**: S3 backend with DynamoDB locking and encryption
- **Enterprise Ready**: Team collaboration, version control, and backup/recovery
- **Robust Cleanup**: Multiple fallback methods ensure complete resource removal

## Prerequisites

**Tailscale OAuth Client**: Create in [Tailscale Admin Console](https://login.tailscale.com/admin/settings/oauth)
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

**AWS CLI**: Configured with appropriate permissions for Lightsail, S3, DynamoDB, and SSM

## Quick Start

**Single command deployment:**
```bash
./deploy.sh
```

**Single command cleanup:**
```bash
./cleanup.sh
```

The deployment script automatically:
- Sets up S3 backend with state locking (first run only)
- Prompts for Tailscale OAuth credentials (first run only)
- Shows interactive region menu (12 regions available)
- Creates workspace for each region
- Deploys exit node with auto-generated name (`ts-virginia`, `ts-london`, etc.)
- **Automatically enables exit node routing** - ready to use immediately!

## Cost

- **Monthly**: ~$3.50 per region (same as bash deployment)
- **Includes**: Instance + IPv4 + 1TB bandwidth + 20GB SSD
- **Backend**: ~$0.02/month (S3 + DynamoDB for state management)
- **Total**: ~$3.52/month per region with enterprise-grade infrastructure

## Available Regions

`virginia`, `ohio`, `oregon`, `ireland`, `london`, `paris`, `frankfurt`, `singapore`, `sydney`, `tokyo`, `mumbai`, `canada`

## Multi-Region Management

- Each region uses its own Terraform workspace
- Deploy/destroy regions independently
- All workspaces share the same S3 backend for centralized state management
- Use `terraform workspace list` to see all deployments
- Switch regions with `terraform workspace select <region>`

## Backend Infrastructure

The deployment automatically creates and manages:

**S3 Backend:**
- Encrypted storage for Terraform state files
- Versioning enabled for point-in-time recovery
- Private bucket with public access blocked
- Centralized state management across all regions

**DynamoDB State Locking:**
- Prevents concurrent modifications
- Pay-per-request billing (minimal cost)
- Automatic conflict resolution

**SSM Parameter Store:**
- Secure OAuth credential storage
- Encrypted at rest with AWS KMS
- Centralized credential management

**Backend Components:**
- `backend-setup/` - Terraform configuration for backend infrastructure
- `.backend-config` - Generated configuration file (git-ignored)
- State files stored as: `s3://bucket/tailscale-exit-nodes/terraform.tfstate`

## Advanced Usage

**Manual Backend Setup:**
```bash
cd backend-setup
terraform init && terraform apply
```

**Manual Credential Management:**
```bash
./setup-credentials.sh
```

**Workspace Management:**
```bash
# List all deployments
terraform workspace list

# Switch to specific region
terraform workspace select ireland

# View deployment details
terraform output
```

**Targeted Cleanup:**
```bash
# Destroy specific resources first
terraform destroy -target=aws_lightsail_instance.tailscale_exit_node

# Then destroy remaining
terraform destroy
```

## Advantages over Bash Scripts

- **State Management**: Terraform tracks infrastructure state in encrypted S3
- **State Locking**: DynamoDB prevents concurrent modifications and corruption
- **OAuth Security**: No manual key handling, expiration, or rotation concerns
- **Secure Credential Storage**: OAuth credentials stored in AWS SSM Parameter Store
- **Backup & Recovery**: Versioned state files with point-in-time recovery
- **Idempotent**: Safe to re-run, only changes what's needed
- **Multi-Region**: Easy workspace management for multiple deployments
- **Version Control**: Infrastructure changes tracked in git
- **Enterprise Ready**: Remote state, locking, team collaboration, and audit trails
- **Automatic Exit Node**: No manual Tailscale console configuration required
- **Robust Cleanup**: Multiple fallback methods prevent stuck resources

## Troubleshooting

**Backend Issues:**
- Ensure AWS credentials are configured: `aws configure`
- Check S3 bucket permissions and region settings
- Verify DynamoDB table exists and is accessible

**OAuth Issues:**
- Verify Client ID and Secret are correct
- Check OAuth client has required scopes and tags
- Ensure credentials are stored in SSM Parameter Store

**Device Issues:**
- Check Tailscale Admin Console for device registration
- Verify device has `tag:awslightsail` tag
- Confirm exit node routes are advertised

**Cleanup Issues:**
- Use `./cleanup.sh` which has multiple fallback methods
- For stuck resources, try targeted destroy first
- Nuclear option: manually remove from state with `terraform state rm`

## File Structure

```
terraform/
├── deploy.sh              # Main deployment script
├── cleanup.sh             # Robust cleanup script
├── setup-credentials.sh   # OAuth credential setup
├── main.tf                # Core infrastructure
├── variables.tf           # Region mappings and variables
├── outputs.tf             # Deployment outputs
├── user-data.sh           # Instance initialization script
├── backend.tf             # S3 backend configuration
├── backend-setup/         # Backend infrastructure setup
│   └── main.tf
├── credentials/           # OAuth credential management
│   └── main.tf
└── .gitignore            # Git ignore patterns
```

## Security Notes

- OAuth credentials stored encrypted in SSM Parameter Store
- S3 state bucket encrypted at rest with versioning
- DynamoDB state locking prevents concurrent access
- Ephemeral auth keys automatically expire and clean up devices
- All sensitive values marked as sensitive in Terraform
- Backend configuration file excluded from version control

---

**This implementation provides enterprise-grade infrastructure management while maintaining the simplicity of single-command deployment.**