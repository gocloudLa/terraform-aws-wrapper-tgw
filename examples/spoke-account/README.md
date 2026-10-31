# Spoke Account Transit Gateway Example 🚀

This example attaches VPCs in a spoke account to a Transit Gateway shared from the network account through AWS RAM, and adds routes from the spoke VPC route tables toward the TGW.

## 🔧 What's Included

### Analysis of Terraform Configuration

#### Main Purpose
The main purpose is to show the spoke side of a multi-account TGW: create_tgw = false, the shared TGW found by ASN, VPC attachments without default table flags, and vpc_routes. Association and propagation of these attachments are managed from the TGW owner account.

#### Key Features Demonstrated
- **Shared TGW**: `create_tgw = false` with `amazon_side_asn` to find the TGW shared through RAM.
- **VPC attachments**: One attachment per VPC key with one private subnet per AZ; the default table flags are omitted because a spoke account cannot change them.
- **VPC routes toward TGW (vpc_routes)**: Routes to the network account VPCs and to on-premises through the TGW.
- **Deploy order**: Owner account first (TGW and RAM share), then this stack, then the owner again to associate and propagate the new attachment (`attachments` with `owner_id`). Destroy in reverse: spokes first.

## 🚀 Quick Start

```bash
terraform init
terraform plan
terraform apply
```

## 🔒 Security Notes

⚠️ **Production Considerations**: 
- This example may include configurations that are not suitable for production environments
- Review and customize security settings, access controls, and resource configurations
- Ensure compliance with your organization's security policies
- Consider implementing proper monitoring, logging, and backup strategies

## 📖 Documentation

For detailed module documentation and additional examples, see the main [README.md](../../README.md) file. 