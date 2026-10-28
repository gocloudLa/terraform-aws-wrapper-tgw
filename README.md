# Standard Platform - Terraform Module 🚀🚀
<p align="right"><a href="https://partners.amazonaws.com/partners/0018a00001hHve4AAC/GoCloud"><img src="https://img.shields.io/badge/AWS%20Partner-Advanced-orange?style=for-the-badge&logo=amazonaws&logoColor=white" alt="AWS Partner"/></a><a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-green?style=for-the-badge&logo=apache&logoColor=white" alt="LICENSE"/></a></p>

Welcome to the Standard Platform — a suite of reusable and production-ready Terraform modules purpose-built for AWS environments.
Each module encapsulates best practices, security configurations, and sensible defaults to simplify and standardize infrastructure provisioning across projects.

## 📦 Module: Terraform Transit Gateway Module
<p align="right"><a href="https://github.com/gocloudLa/terraform-aws-wrapper-tgw/releases/latest"><img src="https://img.shields.io/github/v/release/gocloudLa/terraform-aws-wrapper-tgw.svg?style=for-the-badge" alt="Latest Release"/></a><a href=""><img src="https://img.shields.io/github/last-commit/gocloudLa/terraform-aws-wrapper-tgw.svg?style=for-the-badge" alt="Last Commit"/></a><a href="https://registry.terraform.io/modules/gocloudLa/wrapper-tgw/aws"><img src="https://img.shields.io/badge/Terraform-Registry-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform Registry"/></a></p>
The Terraform Wrapper for Transit Gateway simplifies the configuration of AWS Transit Gateway networking (TGW / VPC attachments / TGW route tables & static routes / RAM sharing / VPC routes to TGW / etc.).

### ✨ Features

- 📡 [RAM sharing and auto-accept](#ram-sharing-and-auto-accept) - Share the Transit Gateway with other accounts and accept attachments automatically

- 🔀 [Multi-VPC attachments and TGW routes](#multi-vpc-attachments-and-tgw-routes) - One subnet per AZ, DNS/IPv6 toggles, and TGW static routes (including blackholes)

- 🗺️ [Named TGW route tables](#named-tgw-route-tables) - Multiple route tables, data-source attachments, per-attachment association

- 🛤️ [vpc_routes (wrapper extension)](#vpc_routes-(wrapper-extension)) - Symmetric `aws_route` entries from each VPC toward remote CIDRs via the TGW

- ⚙️ [Optional TGW settings (commented in examples/complete)](#optional-tgw-settings-(commented-in-examples/complete)) - Uncomment to tune creation, ASN, features, and RAM extras



### 🔗 External Modules
| Name | Version |
|------|------:|
| <a href="https://github.com/terraform-aws-modules/terraform-aws-transit-gateway" target="_blank">terraform-aws-modules/transit-gateway/aws</a> | 3.3.1 |



## 🚀 Quick Start
```hcl
tgw_parameters = {
  "tgw-01" = {
    share_tgw                             = true
    ram_principals                        = ["123456789"]
    enable_auto_accept_shared_attachments = true

    vpc_attachments = {
      "prod" = {
        subnet_ids                                      = ["private-us-east-1a", "private-us-east-1b", "private-us-east-1c"]
        dns_support                                     = true
        ipv6_support                                    = false
        transit_gateway_default_route_table_association = true
        transit_gateway_default_route_table_propagation = true
        tgw_routes = [
          { destination_cidr_block = "10.15.0.0/16" },
          { blackhole = true, destination_cidr_block = "0.0.0.0/0" },
        ]
      }
      "dev" = {
        subnet_ids   = ["private-us-east-1a", "private-us-east-1b", "private-us-east-1c"]
        dns_support  = true
        ipv6_support = false
        tgw_routes = [
          { destination_cidr_block = "10.16.0.0/16" },
          { blackhole = true, destination_cidr_block = "0.0.0.0/0" },
        ]
      }
    }

    vpc_routes = {
      "prod" = {
        "private" = { destination_cidr_block = ["10.16.0.0/16", "10.17.0.0/16"] }
        "public"  = { destination_cidr_block = ["10.16.0.0/16", "10.17.0.0/16"] }
      }
      "dev" = {
        "private" = { destination_cidr_block = ["10.15.0.0/16", "10.17.0.0/16"] }
        "public"  = { destination_cidr_block = ["10.15.0.0/16", "10.17.0.0/16"] }
      }
    }
  }
}
```


## 🔧 Additional Features Usage

### RAM sharing and auto-accept
Same pattern as `examples/complete/main.tf`: `share_tgw`, `ram_principals`, and `enable_auto_accept_shared_attachments`. Use real account IDs, Organization ARNs, or OU ARNs instead of placeholders.


<details><summary>RAM (as in examples/complete)</summary>

```hcl
share_tgw                             = true
ram_principals                        = ["123456789"]
enable_auto_accept_shared_attachments = true
```


</details>


### Multi-VPC attachments and TGW routes
Map keys (`prod`, `dev`, …) must match VPC keys from the VPC wrapper. `subnet_ids` use the same logical names as subnet keys (e.g. `private-us-east-1a`). `tgw_routes` programs the upstream module’s TGW route table (VPC CIDR route plus optional `blackhole` for 0.0.0.0/0), per [variables.tf](https://raw.githubusercontent.com/terraform-aws-modules/terraform-aws-transit-gateway/refs/heads/master/variables.tf).


<details><summary>Two attachments with tgw_routes (from examples/complete)</summary>

```hcl
vpc_attachments = {
  "prod" = {
    subnet_ids = ["private-us-east-1a", "private-us-east-1b", "private-us-east-1c"]
    dns_support                                     = true
    ipv6_support                                    = false
    transit_gateway_default_route_table_association = true
    transit_gateway_default_route_table_propagation = true
    tgw_routes = [
      { destination_cidr_block = "10.15.0.0/16" },
      { blackhole = true, destination_cidr_block = "0.0.0.0/0" },
    ]
  }
  "dev" = {
    subnet_ids   = ["private-us-east-1a", "private-us-east-1b", "private-us-east-1c"]
    dns_support  = true
    ipv6_support = false
    tgw_routes = [
      { destination_cidr_block = "10.16.0.0/16" },
      { blackhole = true, destination_cidr_block = "0.0.0.0/0" },
    ]
  }
}
```


</details>


### Named TGW route tables
`route_tables` creates named TGW route tables (`${common_name}-tgw-rt-<key>`). Set `vpc_attachments.<vpc>.transit_gateway_route_table` to choose the table when the attachment is created (that also defaults default-RT association/propagation to false for the attachment). Extra attachments (VPN, remote VPCs) are discovered with `attachments` (Name tag or `id`) and can `associate` plus appear in `propagations` / `static_routes`. AWS RAM cannot share TGW route tables; associations stay in the TGW owner account. When `route_tables` is set, default TGW association/propagation and the upstream extra table are off unless you override them.


<details><summary>Named tables and attachment association</summary>

```hcl
enable_default_route_table_association = false
enable_default_route_table_propagation = false

attachments = {
  vpn-01 = { resource_type = "vpn", name = "jus-net-vpn-01", associate = "hybrid" }
  gel    = { name = "jus-gel-tgw-01-vpc-01" }
}

vpc_attachments = {
  vpc-01 = {
    subnet_ids                                      = ["private-a", "private-b", "private-c"]
    transit_gateway_default_route_table_association = false
    transit_gateway_default_route_table_propagation = false
    transit_gateway_route_table                     = "shared"
  }
}

route_tables = {
  shared = { propagations = ["gel", "vpn-01"] }
  hybrid = { propagations = ["vpc-01"] }
  spoke-gel = {
    propagations = ["vpn-01", "vpc-01"]
    static_routes = [
      { destination_cidr_block = "0.0.0.0/0", attachment = "vpc-01" },
      { destination_cidr_block = "10.81.64.0/18", blackhole = true },
    ]
  }
}
```


</details>


### vpc_routes (wrapper extension)
Top-level `vpc_routes` matches `examples/complete`: for each VPC key and route table name, list IPv4 CIDRs that should point at the Transit Gateway. Route table keys must exist in `vpc_parameter.route_tables` as `{vpc_key}-{route_table_name}`.


<details><summary>Private and public route tables (from examples/complete)</summary>

```hcl
vpc_routes = {
  "prod" = {
    "private" = { destination_cidr_block = ["10.16.0.0/16", "10.17.0.0/16"] }
    "public"  = { destination_cidr_block = ["10.16.0.0/16", "10.17.0.0/16"] }
  }
  "dev" = {
    "private" = { destination_cidr_block = ["10.15.0.0/16", "10.17.0.0/16"] }
    "public"  = { destination_cidr_block = ["10.15.0.0/16", "10.17.0.0/16"] }
  }
}
```


</details>


### Optional TGW settings (commented in examples/complete)
The complete example documents optional keys as comments (`create_tgw`, `create_tgw_routes`, `description`, `amazon_side_asn`, default association/propagation, multicast, VPN ECMP, DNS, SG referencing, encryption, `region`, `transit_gateway_cidr_blocks`, `transit_gateway_route_table_id`, `ram_allow_external_principals`, `ram_name`). Enable them when needed; semantics match the upstream transit-gateway module.





## 📑 Inputs
| Name                                   | Description                                                                                                                                                                                   | Type           | Default                              | Required |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- | ------------------------------------ | -------- |
| create_tgw                             | Whether to create the Transit Gateway.                                                                                                                                                        | `bool`         | `true`                               | no       |
| name                                   | Resource name identifier.                                                                                                                                                                     | `string`       | `"${local.common_name}-${each.key}"` | no       |
| description                            | Transit Gateway description.                                                                                                                                                                  | `string`       | `null`                               | no       |
| amazon_side_asn                        | Amazon-side ASN.                                                                                                                                                                              | `string`       | `64512`                              | no       |
| enable_default_route_table_association | Auto-associate attachments with default association route table.                                                                                                                              | `bool`         | `true`                               | no       |
| enable_default_route_table_propagation | Auto-propagate routes to default propagation route table.                                                                                                                                     | `bool`         | `true`                               | no       |
| enable_auto_accept_shared_attachments  | Auto-accept shared attachment requests.                                                                                                                                                       | `bool`         | `false`                              | no       |
| enable_vpn_ecmp_support                | VPN ECMP support.                                                                                                                                                                             | `bool`         | `true`                               | no       |
| enable_multicast_support               | Multicast support.                                                                                                                                                                            | `bool`         | `false`                              | no       |
| enable_dns_support                     | DNS support on the TGW.                                                                                                                                                                       | `bool`         | `true`                               | no       |
| enable_sg_referencing_support          | Security group referencing on the TGW.                                                                                                                                                        | `bool`         | `true`                               | no       |
| enable_encryption_support              | Encryption support on the TGW.                                                                                                                                                                | `bool`         | `false`                              | no       |
| region                                 | AWS region for the TGW and wrapper-owned resources.                                                                                                                                           | `string`       | `metadata.aws_region` then provider  | no       |
| transit_gateway_cidr_blocks            | TGW CIDR blocks (IPv4 /24+ or IPv6 /64+).                                                                                                                                                     | `list(string)` | `[]`                                 | no       |
| create_tgw_routes                      | Create TGW route table and routes (e.g. from attachment `tgw_routes`).                                                                                                                        | `bool`         | `true`                               | no       |
| transit_gateway_route_table_id         | Existing route table ID when reusing a TGW.                                                                                                                                                   | `string`       | `null`                               | no       |
| share_tgw                              | Share the TGW through RAM.                                                                                                                                                                    | `bool`         | `false`                              | no       |
| ram_name                               | RAM resource share name.                                                                                                                                                                      | `string`       | `"${local.common_name}-${each.key}"` | no       |
| ram_allow_external_principals          | Allow principals outside the organization.                                                                                                                                                    | `bool`         | `false`                              | no       |
| ram_principals                         | Account IDs, Organization ARNs, or OU ARNs.                                                                                                                                                   | `list(string)` | `[]`                                 | no       |
| ram_resource_share_arn                 | Existing RAM share ARN.                                                                                                                                                                       | `string`       | `""`                                 | no       |
| tags                                   | Tags for all resources (upstream `tags`).                                                                                                                                                     | `map(string)`  | `local.common_tags`                  | no       |
| vpc_attachments                        | Map of VPC attachments (`any` upstream); wrapper resolves `vpc_id` and `subnet_ids` from `vpc_parameter`. Set `transit_gateway_route_table` to a `route_tables` key to associate at creation. | `any`          | `{}`                                 | no       |
| vpc_routes                             | **Wrapper-only:** `vpc_routes.<vpc>.<route_table>.destination_cidr_block` → `aws_route` to TGW.                                                                                               | `any`          | `{}`                                 | no       |
| route_tables                           | **Wrapper-only:** named TGW route tables (`propagations`, `static_routes`, `name`).                                                                                                           | `any`          | `{}`                                 | no       |
| attachments                            | **Wrapper-only:** extra attachments by Name/`id` for association and propagation.                                                                                                             | `any`          | `{}`                                 | no       |







## ⚠️ Important Notes
- **Upstream reference**: Nested module is `terraform-aws-modules/transit-gateway/aws` `3.3.1`. Field names align with that version’s `variables.tf`.
- **Region**: `region` on a TGW entry or `tgw_defaults.region` overrides `metadata.aws_region`, then the AWS provider region (`data.aws_region.current`). Same pattern as other GoCloud wrappers.
- **Subnet and route table keys**: `vpc_parameter.subnets` keys must be `{vpc_key}-{subnet_group}-{az_key}` (same as the VPC wrapper). `vpc_parameter.route_tables` keys must be `{vpc_key}-{route_table_name}`.
- **Existing Transit Gateway**: When `create_tgw = false`, the wrapper uses a data source filtered by `options.amazon-side-asn` (default `64512` in this repo unless overridden); use a unique ASN or adjust the data source if multiple gateways share the default ASN.
- **Full example**: See `examples/complete` for a richer `tgw_parameters` map.
- **RAM and AWS Organizations**: To share the Transit Gateway with organization accounts without invitations, turn on **Resource Access Manager → Settings → Enable sharing with AWS Organizations** in the **organization’s management account**. The organization must have **all features** enabled.



---

## 🤝 Contributing
We welcome contributions! Please see our contributing guidelines for more details.

## 🆘 Support
- 📧 **Email**: info@gocloud.la

## 🧑‍💻 About
We are focused on Cloud Engineering, DevOps, and Infrastructure as Code.
We specialize in helping companies design, implement, and operate secure and scalable cloud-native platforms.
- 🌎 [www.gocloud.la](https://www.gocloud.la)
- ☁️ AWS Advanced Partner (Terraform, DevOps, GenAI)
- 📫 Contact: info@gocloud.la

## 📄 License
This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details. 