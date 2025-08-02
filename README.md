# Multi-Region Tailscale Exit Node Deployment

Cost-optimized, automated CloudFormation deployment for Tailscale exit nodes across multiple AWS regions.

## Features

- **Cost Optimized**: Uses t4g.nano instances (~$7.44/month per region)
- **Internet Gateway**: No NAT Gateway costs (saves ~$45/month per region)
- **Automated Setup**: Tailscale installed and registered automatically
- **Multi-Region**: Deploy to any AWS regions you specify
- **Secure**: Restricted security groups, no SSH access

## Prerequisites

1. **Tailscale Auth Key**: Generate from [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)

   **Step-by-step:**

   - Navigate to Settings → Keys in your Tailscale admin console
   - Click "Generate auth key"
   - Configure the key:
     - ❌ **Reusable**: Leave unchecked for single-use keys
     - ✅ **Ephemeral**: Nodes auto-cleanup when offline (recommended)
     - ✅ **Preauthorized**: Skip manual approval for new nodes
     - **Expiry**: Set to 1-7 days (sufficient for deployment)
     - **Tags**: Optional, use `tag:exitnode` for organization
   - Copy the generated key (starts with `tskey-auth-`) for immediate use

   **Note**: Generate a fresh single-use auth key for each deployment. Keys expire automatically and cannot be reused.
2. **AWS CLI**: Configured with appropriate permissions

## Quick Start

1. **Make scripts executable**:

   ```bash
   chmod +x deploy-interactive.sh cleanup-interactive.sh
   ```
2. **Deploy to a region**:

   ```bash
   ./deploy-interactive.sh
   ```

   - Prompts for Tailscale auth key
   - Select from your enabled AWS regions
   - Automatically fetches latest ARM64 AMI
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

### Instance Types (Monthly Cost Estimates)

- `t4g.nano`: ~$3.04/month (ARM64, default, cheapest)
- `t4g.micro`: ~$6.08/month (ARM64)
- `t3.nano`: ~$3.80/month (x86_64)
- `t3.micro`: ~$7.60/month (x86_64)

### Security Groups

- **Tailscale**: UDP 41641 (required)
- **Outbound**: All traffic allowed (required for exit node)
- **No SSH**: Access removed for security (redeploy if maintenance needed)

### Network Configuration

- **VPC CIDR**: 192.168.100.0/24 (RFC1918 compliant)
- **Single AZ**: Cost-optimized deployment
- **Instance Names**: ts-{friendly-name} (e.g., ts-virginia, ts-stockholm)

### Supported Regions

- Any enabled AWS region that supports t4g.nano instances
- Script automatically lists your account's enabled regions
- ARM64 AMI automatically fetched for each region
- If regions are missing, enable them in your AWS account settings

## Manual Deployment

```bash
aws cloudformation deploy \
  --template-file tailscale-exit-node.yaml \
  --stack-name tailscale-exit-node-us-east-1 \
  --parameter-overrides \
    TailscaleAuthKey="tskey-auth-xxxxx" \
    InstanceType="t4g.nano" \
    AMIId="ami-xxxxxxxxx" \
  --capabilities CAPABILITY_IAM \
  --region us-east-1
```

## Cleanup

Remove a deployment:

```bash
./cleanup-interactive.sh
```

## Security Recommendations

1. **No SSH Access**: SSH completely disabled for security
2. **Use Ephemeral Keys**: Enable ephemeral auth keys in Tailscale
3. **Monitor Usage**: Set up CloudWatch alarms for unexpected traffic
4. **Automatic Updates**: AMI IDs are automatically fetched for latest security patches

## Troubleshooting

### Instance not appearing in Tailscale

- Check CloudFormation stack events for errors
- Verify auth key is valid and not expired
- Redeploy stack if troubleshooting needed

### High costs

- Ensure using t4g.nano instances
- Verify no NAT Gateways were created
- Monitor data transfer costs

### Connection issues

- Check security group allows UDP 41641
- Verify instance has public IP
- Confirm internet gateway is attached

## Cost Breakdown (per region)

- **EC2 t4g.nano**: ~$3.04/month
- **EBS gp3 8GB**: ~$0.80/month
- **IPv4 Public IP**: ~$3.60/month
- **Data Transfer**: Variable (first 1GB free)
- **VPC/Networking**: Free (within limits)
- **CloudFormation**: Free
- **Total**: ~$7.44/month per region (~£5.90/month)

*Costs may vary by region and usage patterns. IPv4 pricing effective February 2024.*
