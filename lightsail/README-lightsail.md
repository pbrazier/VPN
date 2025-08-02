# Lightsail Tailscale Exit Node Deployment

Cost-optimized AWS Lightsail deployment for Tailscale exit nodes with significant cost savings over EC2.

## Features

- **Ultra Cost Optimized**: Uses Lightsail nano instances (~$3.50/month per region)
- **Fixed Pricing**: Includes bandwidth, IPv4, and storage in one price
- **Simplified Deployment**: No CloudFormation or VPC setup required
- **Automated Setup**: Tailscale installed and registered automatically
- **Multi-Region**: Deploy to any Lightsail regions
- **Secure**: Minimal attack surface with automatic security updates

## Cost Comparison

| Service | Monthly Cost | Includes |
|---------|-------------|----------|
| **Lightsail** | ~$3.50 | Instance + IPv4 + 1TB bandwidth + 20GB SSD |
| **EC2** | ~$7.44 | Instance + IPv4 (separate charges) |
| **Savings** | **~53%** | Fixed predictable pricing |

## Prerequisites

1. **Tailscale Auth Key**: Generate from [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)

   **Step-by-step:**
   - Navigate to Settings → Keys in your Tailscale admin console
   - Click "Generate auth key"
   - Configure the key:
     - ❌ **Reusable**: Leave unchecked for single-use keys
     - ❌ **Ephemeral**: Leave unchecked
     - ✅ **Preauthorized**: Skip manual approval for new nodes
     - **Expiry**: Set to 1-7 days (sufficient for deployment)
     - **Tags**: Optional, use `tag:exitnode` for organization
   - Copy the generated key (starts with `tskey-auth-`) for immediate use

   **Note**: Generate a fresh single-use auth key for each deployment.

2. **AWS CLI**: Configured with Lightsail permissions

## Quick Start

1. **Make scripts executable**:
   ```bash
   chmod +x deploy-lightsail.sh cleanup-lightsail.sh
   ```

2. **Deploy to a region**:
   ```bash
   ./deploy-lightsail.sh
   ```
   - Prompts for Tailscale auth key
   - Select from available Lightsail regions
   - Automatically creates and configures instance

3. **Verify deployment**:
   ```bash
   tailscale status
   ```

4. **Configure exit node** (required):
   - Go to [Tailscale Admin Console](https://login.tailscale.com/admin/machines)
   - Find your new node (e.g., `ts-virginia`)
   - Click the node name to open settings
   - Under "Exit node" section, check "Use as exit node"
   - Click "Save"
   - Under "General" section, click "Disable key expiry" to prevent automatic disconnection
   - Click "Save"

## Configuration

### Instance Specifications
- **Bundle**: nano_3_0 (512MB RAM, 1 vCPU, 20GB SSD)
- **OS**: Amazon Linux 2023
- **Bandwidth**: 1TB included
- **IPv4**: Static IP included
- **Instance Names**: ts-{friendly-name} (e.g., ts-virginia, ts-stockholm)

### Supported Regions
- us-east-1 (N. Virginia)
- us-east-2 (Ohio)  
- us-west-2 (Oregon)
- eu-west-1 (Ireland)
- eu-west-2 (London)
- eu-west-3 (Paris)
- eu-central-1 (Frankfurt)
- ap-southeast-1 (Singapore)
- ap-southeast-2 (Sydney)
- ap-northeast-1 (Tokyo)
- ap-south-1 (Mumbai)
- ca-central-1 (Canada Central)

*Note: Scripts automatically detect new regions as AWS adds them. Current regions listed above.*

## Manual Deployment

```bash
aws lightsail create-instances \
  --instance-names "ts-virginia" \
  --availability-zone "us-east-1a" \
  --blueprint-id "amazon_linux_2023" \
  --bundle-id "nano_3_0" \
  --user-data "$(cat user-data-script.sh)" \
  --tags "key=project,value=tailscale" \
  --region us-east-1
```

## Cleanup

Remove a deployment:
```bash
./cleanup-lightsail.sh
```

## Security Features

1. **Automatic Firewall Configuration**: Closes SSH/HTTP ports after deployment
2. **Browser SSH Only**: Access only via Lightsail console (no external SSH)
3. **Minimal Attack Surface**: Only Tailscale traffic allowed
4. **Automatic Updates**: Amazon Linux 2023 with security patches

## Advantages over EC2

1. **Fixed Pricing**: No surprise IPv4 or bandwidth charges
2. **Simpler Management**: No VPC, subnets, or security groups to configure
3. **Included Bandwidth**: 1TB transfer included (vs. pay-per-GB on EC2)
4. **Automatic Backups**: Available for additional cost
5. **Predictable Costs**: Perfect for budgeting

## Limitations

1. **Fewer Regions**: Limited compared to EC2's global presence
2. **Less Customization**: Fixed instance sizes and configurations
3. **No Spot Instances**: Can't use spot pricing for additional savings
4. **Bandwidth Limits**: 1TB included, then additional charges apply

## Security Recommendations

1. **Automatic Updates**: Lightsail instances auto-update by default
2. **Use Ephemeral Keys**: Generate fresh auth keys for each deployment
3. **Monitor Usage**: Check bandwidth usage in Lightsail console
4. **Regular Maintenance**: Instances are managed but monitor Tailscale status

## Troubleshooting

### Instance not appearing in Tailscale
- Check instance logs: `aws lightsail get-instance-metric-data`
- Verify auth key is valid and not expired
- Redeploy instance if troubleshooting needed

### High bandwidth usage
- Monitor in Lightsail console
- 1TB included, additional usage charged separately
- Consider upgrading bundle if consistently over limit

### Connection issues
- Lightsail instances have automatic firewall rules
- Tailscale handles connectivity through its mesh network
- Check instance is in "running" state

## Cost Breakdown (per region)

- **Lightsail nano_3_0**: $3.50/month
- **Includes**: 512MB RAM, 1 vCPU, 20GB SSD, 1TB bandwidth, IPv4 address
- **Total**: ~$3.50/month per region (~£2.77/month)

*Fixed pricing with no hidden costs. Bandwidth overage: $0.09/GB*

## Migration from EC2

To migrate from the EC2 solution:
1. Deploy new Lightsail instance in same region
2. Verify Tailscale connectivity
3. Update exit node configuration in Tailscale admin
4. Remove old EC2 stack
5. **Save ~53% on monthly costs**