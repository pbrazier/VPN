# EC2 Implementation (Superseded)

⚠️ **This EC2 implementation has been superseded by the Lightsail version.**

## Why Lightsail is Preferred

- **53% cost savings**: $3.50/month vs $7.44/month
- **Fixed pricing**: No surprise IPv4 or bandwidth charges
- **Simpler deployment**: No CloudFormation complexity
- **Better security**: Automatic firewall hardening
- **Same functionality**: Identical Tailscale exit node features

## Migration Recommendation

**Use the Lightsail implementation instead:**
```bash
cd ../lightsail
./deploy-lightsail.sh
```

## EC2 Implementation Details

This folder contains the original EC2-based deployment:

- **`deploy-interactive.sh`** - Interactive EC2 deployment
- **`cleanup-interactive.sh`** - Interactive EC2 cleanup  
- **`tailscale-exit-node.yaml`** - CloudFormation template

### Cost Breakdown (EC2)
- **EC2 t4g.nano**: ~$3.04/month
- **EBS gp3 8GB**: ~$0.80/month
- **IPv4 Public IP**: ~$3.60/month
- **Total**: ~$7.44/month per region

### Why It's Superseded
1. **Higher costs** due to separate IPv4 pricing
2. **Complex infrastructure** with VPC/CloudFormation
3. **More maintenance** overhead
4. **Same functionality** available cheaper on Lightsail

**Recommendation**: Use `../lightsail/` for all new deployments.