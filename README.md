# Tailscale Exit Node Deployment

Cost-optimized AWS deployment for Tailscale exit nodes with multiple implementation options.

## Recommended: Lightsail Implementation

**Use the Lightsail version for new deployments:**

```bash
cd lightsail
./deploy-lightsail.sh
```

### Why Lightsail?
- **53% cheaper**: $3.50/month vs $7.44/month (EC2)
- **Fixed pricing**: Includes instance, IPv4, storage, 1TB bandwidth
- **Simpler deployment**: No CloudFormation complexity
- **Better security**: Automatic firewall hardening
- **Same functionality**: Identical Tailscale exit node features

## Implementation Options

### 1. Terraform (Recommended) - `terraform/`
- **Cost**: ~$3.50/month per region
- **Deployment**: Fully automated with enterprise features
- **Infrastructure**: Lightsail with S3 backend state management
- **Security**: SSH restricted to deployment IP, Tailscale OAuth integration, encrypted state
- **Features**: Multi-region workspaces, automatic exit node configuration, AWS auth validation

### 2. Legacy Implementations - `superseded/`
- **Lightsail Bash**: Simple bash scripts (superseded by Terraform)
- **EC2 CloudFormation**: Custom VPC setup (superseded by Lightsail)
- **Status**: Maintained for reference but not recommended for new deployments

## Quick Start (Terraform - Recommended)

1. **Navigate to Terraform folder**:
   ```bash
   cd terraform
   ```

2. **Deploy to a region**:
   ```bash
   ./deploy.sh
   ```
   - Validates AWS authentication upfront
   - Automatically sets up S3 backend (first run)
   - Checks for Tailscale OAuth credentials (prompts if missing)
   - Select from 13 available regions (including Stockholm)
   - **Automatically configures exit node** - no manual steps!
   - **Secure by default**: SSH restricted to your IP, no HTTP access

3. **Remove deployment**:
   ```bash
   ./cleanup.sh
   ```

**Legacy Quick Start** (superseded implementations in `superseded/` folder)

## Prerequisites

- **AWS CLI**: Configured with Lightsail permissions and authenticated
- **Tailscale OAuth**: Client ID/Secret stored in AWS Parameter Store (prompted if missing)

## Security Features

- **SSH Access**: Restricted to external IP address of network executing Terraform (auto-detected)
- **No HTTP Access**: Port 80 completely blocked
- **Outbound Only**: Tailscale requires no inbound connections
- **Tailscale OAuth**: Client ID/Secret stored encrypted in AWS Parameter Store
- **State Encryption**: Terraform state encrypted in S3 with DynamoDB locking

## Folder Structure

```
├── terraform/              # Recommended implementation
│   ├── deploy.sh            # Main deployment script
│   ├── cleanup.sh           # Cleanup script
│   ├── main.tf              # Core infrastructure
│   ├── scripts/             # All executable scripts
│   ├── modules/             # Terraform modules
│   └── README.md            # Detailed documentation
│
├── superseded/             # Legacy implementations
│   ├── lightsail/           # Bash script implementation
│   └── ec2-superseded/      # CloudFormation implementation
│
└── README.md               # This file
```

## Cost Comparison

| Implementation | Monthly Cost | Includes |
|---------------|-------------|----------|
| **Terraform** (Recommended) | **$3.52** | Instance + IPv4 + 1TB bandwidth + 20GB SSD + S3 backend + Security |
| Lightsail Bash (Superseded) | $3.50 | Instance + IPv4 + 1TB bandwidth + 20GB SSD |
| EC2 (Superseded) | $7.44 | Instance + IPv4 (separate charges) |
| **Enterprise Features** | **+$0.02** | S3 backend, DynamoDB locking, OAuth, multi-region, IP-restricted SSH |

*Terraform implementation adds enterprise-grade features for minimal additional cost.*