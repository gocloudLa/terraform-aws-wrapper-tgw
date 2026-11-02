# Legacy TGW Routes Example 🚀

This example keeps the original single extra route table layout (create_tgw_routes = true) with per-attachment tgw_routes, for reference. The wrapper does not forward tgw_routes to the upstream module, so those routes are not created.

## 🔧 What's Included

### Analysis of Terraform Configuration

#### Main Purpose
The main purpose is to document the pre-route_tables configuration still found in existing stacks. Use examples/complete (route_tables with static_routes) for new stacks.

#### Key Features Demonstrated
- **Extra route table**: `create_tgw_routes = true` (default) creates one extra table; attachments with default association/propagation set to false use it, the rest stay on the AWS default tables.
- **tgw_routes (legacy, no effect)**: Per-attachment routes and a 0.0.0.0/0 blackhole as written in older stacks; not forwarded by the wrapper.
- **Migration**: Move these routes to `route_tables.<key>.static_routes` and set `create_tgw_routes = false` (see the root README migration note).
- **VPC routes toward TGW (vpc_routes)**: Same as in the complete example.

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