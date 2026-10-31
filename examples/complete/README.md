# Complete Transit Gateway Example 🚀

This example deploys a Transit Gateway in the network account with RAM sharing, auto-accept of shared attachments, two VPC attachments (prod and dev), three named TGW route tables (shared, hybrid, spoke) with associations, propagations and a default static route, attachments discovered by Name tag, and vpc_routes that point each VPC route table at the TGW.

## 🔧 What's Included

### Analysis of Terraform Configuration

#### Main Purpose
The main purpose is to show the named route table model of the wrapper: which table each attachment associates with, which tables learn its prefixes, where static routes and blackholes go, and how the TGW-level default table flags interact with route_tables.

#### Key Features Demonstrated
- **Layout**: main.tf (module only), variables.tf (vpc_parameter), metadata.tf (metadata, common_name), providers.tf, outputs.tf.
- **Transit Gateway instance**: One TGW key (`tgw-01`) with share_tgw, a placeholder ram_principals account and enable_auto_accept_shared_attachments; optional TGW fields are commented.
- **Default table flags**: `enable_default_route_table_association` / `_propagation` set explicitly to `false`; changing either from false to true replaces the TGW.
- **Named route tables (route_tables)**: `shared`, `hybrid` and `spoke` with `propagations` and `static_routes` (attachment target); `create_tgw_routes = false` is required with route_tables.
- **Associations**: VPC attachments use `transit_gateway_route_table`; VPN and remote VPC attachments are discovered under `attachments` and use `associate`.
- **VPC routes toward TGW (vpc_routes)**: Map by VPC key and route table name with destination_cidr_block lists; drives aws_route resources in each VPC.

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