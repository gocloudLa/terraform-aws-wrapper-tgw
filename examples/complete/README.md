# Complete Transit Gateway Example 🚀

This example demonstrates a Transit Gateway setup using the wrapper module with RAM sharing, auto-accept of shared attachments, two VPC attachments (prod and dev) over three private subnets per AZ, TGW route table entries (including a blackhole default), optional per-attachment vpc_routes metadata, and top-level vpc_routes that create aws_route entries in each VPC route table toward the TGW.

## 🔧 What's Included

### Analysis of Terraform Configuration

#### Main Purpose
The main purpose is to showcase how tgw_parameters maps to terraform-aws-modules/transit-gateway: metadata and vpc_parameter wiring (from the VPC wrapper outputs or tfvars), attachment keys aligned with VPC keys, and commented placeholders for TGW-level options (create_tgw, ASN, route tables, multicast, VPN ECMP, DNS, CIDR blocks).

#### Key Features Demonstrated
- **Layout**: Same file split as the VPC complete example — main.tf (module only), variables.tf (vpc_parameter), metadata.tf (metadata, common_name, common_tags), providers.tf, data_sources.tf, outputs.tf.
- **Transit Gateway instance**: One logical TGW key (`tgw-01`) with share_tgw, ram_principals placeholder, and enable_auto_accept_shared_attachments; many TGW fields left commented for optional tuning.
- **VPC attachments**: Attachments `prod` and `dev` with private subnets per AZ (one subnet per AZ), dns_support, ipv6_support, and default association/propagation flags; subnet_ids use the same naming convention as the VPC wrapper (`{group}-{region}{az}`).
- **TGW routes (tgw_routes)**: Per-attachment routes toward the VPC CIDR and a blackhole for 0.0.0.0/0, as consumed by the upstream transit-gateway module.
- **VPC routes toward TGW (vpc_routes)**: Top-level map by VPC key and route table name with destination_cidr_block lists; drives aws_route resources in the wrapper. The prod attachment also illustrates nested vpc_routes for documentation parity with lab configs.
- **vpc_parameter**: Supplied via variable (default {}) so you can pass module.wrapper_vpc outputs (vpcs, subnets, route_tables) from a root module or tfvars.

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