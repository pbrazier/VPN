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

### 1. Lightsail (Recommended) - `lightsail/`
- **Cost**: ~$3.50/month per region
- **Deployment**: Simple bash scripts
- **Infrastructure**: Managed Lightsail instances
- **Security**: Automatic firewall configuration

### 2. EC2 (Superseded) - `ec2-superseded/`
- **Cost**: ~$7.44/month per region  
- **Deployment**: CloudFormation templates
- **Infrastructure**: Custom VPC setup
- **Status**: Superseded by Lightsail implementation

## Quick Start (Lightsail)

1. **Navigate to Lightsail folder**:
   ```bash
   cd lightsail
   ```

2. **Deploy to a region**:
   ```bash
   ./deploy-lightsail.sh
   ```
   - Prompts for Tailscale auth key
   - Select from available Lightsail regions
   - Automatically configures security

3. **Configure exit node** (required):
   - Go to [Tailscale Admin Console](https://login.tailscale.com/admin/machines)
   - Find your new node (e.g., `ts-virginia`)
   - Enable "Use as exit node" and disable key expiry

4. **Remove deployment**:
   ```bash
   ./cleanup-lightsail.sh
   ```

## Prerequisites

- **Tailscale Auth Key**: Generate single-use key from admin console
- **AWS CLI**: Configured with Lightsail permissions

## Folder Structure

```
├── lightsail/              # Recommended implementation
│   ├── deploy-lightsail.sh  # Interactive deployment
│   ├── cleanup-lightsail.sh # Interactive cleanup
│   └── README-lightsail.md  # Detailed documentation
│
├── ec2-superseded/         # Legacy implementation
│   ├── deploy-interactive.sh
│   ├── cleanup-interactive.sh
│   ├── tailscale-exit-node.yaml
│   └── README.md           # Migration guidance
│
└── README.md              # This file
```

## Cost Comparison

| Implementation | Monthly Cost | Includes |
|---------------|-------------|----------|
| **Lightsail** (Recommended) | **$3.50** | Instance + IPv4 + 1TB bandwidth + 20GB SSD |
| EC2 (Superseded) | $7.44 | Instance + IPv4 (separate charges) |
| **Savings** | **53%** | Fixed predictable pricing |

*Lightsail pricing is fixed and predictable. EC2 costs may vary by region and usage patterns.*