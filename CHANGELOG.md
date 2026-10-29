# Changelog

## Unreleased

### Features

* Named TGW route tables (`route_tables`), attachment discovery (`attachments`), and per-attachment association (`transit_gateway_route_table`)
* Document AWS default vs nested extra vs named TGW route tables: when attachments associate or propagate, and where `tgw_routes` / `static_routes` are created
* Bump nested `terraform-aws-modules/transit-gateway/aws` to 3.3.1; pass `region` from `tgw_parameters` / `tgw_defaults` / `metadata.aws_region` / the AWS provider. `enable_sg_referencing_support` defaults on for the TGW and for VPC attachments (attachment can still override). `enable_encryption_support` defaults off.

### Bug Fixes

* `attachments` discovery accepts `owner_id` (`resource-owner-id`) and `resource_id`; `name` is optional. Cross-account VPC attachment tags are not visible to the TGW owner, so Name-tag lookups failed for spoke VPCs.
* Force `create_tgw_routes = false` when `route_tables` is set so the nested module does not associate attachments to its extra/default table over `transit_gateway_route_table`.
* Drop RAM sharing of TGW route tables. AWS RAM does not support `ec2:TransitGatewayRouteTable`; only the Transit Gateway itself is shareable.

## 0.1.0 (2026-06-29)


### Features

* **ci:** Add Dependabot configuration. ([54658f2](https://github.com/gocloudLa/terraform-aws-wrapper-tgw/commit/54658f2cfe0f0999a4dc03ba5db1eb3702903e62))
* **module:** initial release ([#1](https://github.com/gocloudLa/terraform-aws-wrapper-tgw/issues/1)) ([7f2fa64](https://github.com/gocloudLa/terraform-aws-wrapper-tgw/commit/7f2fa64f0c42a2198b3a763b29a1d91bfc79615f))
