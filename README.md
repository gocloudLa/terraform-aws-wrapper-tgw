# Standard Platform - Terraform Module 🚀🚀
<p align="right"><a href="https://partners.amazonaws.com/partners/0018a00001hHve4AAC/GoCloud"><img src="https://img.shields.io/badge/AWS%20Partner-Advanced-orange?style=for-the-badge&logo=amazonaws&logoColor=white" alt="AWS Partner"/></a><a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-green?style=for-the-badge&logo=apache&logoColor=white" alt="LICENSE"/></a></p>

Welcome to the Standard Platform — a suite of reusable and production-ready Terraform modules purpose-built for AWS environments.
Each module encapsulates best practices, security configurations, and sensible defaults to simplify and standardize infrastructure provisioning across projects.

## 📦 Module: Terraform Transit Gateway Module
<p align="right"><a href="https://github.com/gocloudLa/terraform-aws-wrapper-tgw/releases/latest"><img src="https://img.shields.io/github/v/release/gocloudLa/terraform-aws-wrapper-tgw.svg?style=for-the-badge" alt="Latest Release"/></a><a href=""><img src="https://img.shields.io/github/last-commit/gocloudLa/terraform-aws-wrapper-tgw.svg?style=for-the-badge" alt="Last Commit"/></a><a href="https://registry.terraform.io/modules/gocloudLa/wrapper-tgw/aws"><img src="https://img.shields.io/badge/Terraform-Registry-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform Registry"/></a></p>
The Terraform Wrapper for Transit Gateway simplifies the configuration of AWS Transit Gateway networking (TGW / VPC attachments / TGW route tables & static routes / RAM sharing / VPC routes to TGW / etc.).

### ✨ Features

- 📡 [RAM sharing and auto-accept](#ram-sharing-and-auto-accept) - Share the Transit Gateway with other accounts and accept attachments automatically

- 🔀 [VPC attachments](#vpc-attachments) - One subnet per AZ, DNS/IPv6 toggles, and the route table each attachment uses

- 🧭 [Default vs extra vs named TGW route tables](#default-vs-extra-vs-named-tgw-route-tables) - Which table attachments associate to, where they propagate, and where static routes are created

- 🗺️ [Named TGW route tables](#named-tgw-route-tables) - Multiple route tables, discovered attachments, per-attachment association

- 🏢 [Spoke account attachments](#spoke-account-attachments) - Attach VPCs in another account to a TGW shared through RAM

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
    # Variables to deploy transit gateway resource

    # create_tgw = true
    create_tgw_routes = false # Default: true. Must be false with route_tables (otherwise the nested extra table is created)

    # description                            = "Transit Gateway 01"
    # amazon_side_asn                        = "64512"
    # enable_default_route_table_association = true
    # enable_default_route_table_propagation = true
    # enable_multicast_support               = false
    # enable_vpn_ecmp_support                = true
    # enable_dns_support                     = true
    # enable_sg_referencing_support          = false
    # enable_encryption_support              = false
    # region                                 = "us-east-2" # Default: metadata.aws_region, then the provider region

    # transit_gateway_cidr_blocks    = []
    # transit_gateway_route_table_id = null

    ## Allow the sharing of the TGW using RAM
    share_tgw = true
    ## If enabled you can administer which accounts will have access to the TGW resources
    ram_principals = ["123456789012"]
    # ram_allow_external_principals = false
    # ram_name                      = null
    enable_auto_accept_shared_attachments = true
    # WARNING: changing either flag from false to true REPLACES the Transit Gateway (true -> false is in place).
    # Default: true, or false when route_tables is set, so removing route_tables later also recreates the TGW.
    # Set both explicitly and keep them fixed once the TGW exists.
    enable_default_route_table_association = false
    enable_default_route_table_propagation = false

    ## Named TGW route tables (wrapper extension). Discover VPN/remote VPCs by Name tag.
    attachments = {
      vpn-01 = {
        resource_type = "vpn"
        name          = "example-vpn-01"
        associate     = "hybrid"
      }
      spoke = {
        name = "example-spoke-tgw-01-vpc-01"
      }
    }

    route_tables = {
      shared = {
        propagations = ["spoke", "vpn-01", "dev"]
      }
      hybrid = {
        propagations = ["prod"]
      }
      spoke = {
        propagations = ["vpn-01", "prod"]
        static_routes = [
          { destination_cidr_block = "0.0.0.0/0", attachment = "prod" },
        ]
      }
    }

    ## Managing TGW VPC Attachments
    vpc_attachments = {
      "prod" = {                                                                          //must be the same vpc_name
        subnet_ids   = ["private-us-east-1a", "private-us-east-1b", "private-us-east-1c"] // Only 1 Subnet per AZ
        dns_support  = true
        ipv6_support = false
        # Only set these in the TGW owner account. On a shared TGW (create_tgw = false) AWS ignores them
        # and the provider always reads true, so false shows a perpetual in-place diff. Omit them there;
        # association/propagation is managed from the owner account (route_tables / attachments).
        transit_gateway_default_route_table_association = false
        transit_gateway_default_route_table_propagation = false
        transit_gateway_route_table                     = "shared"
      }
      "dev" = {
        dns_support                 = true
        ipv6_support                = false
        subnet_ids                  = ["private-us-east-1a", "private-us-east-1b", "private-us-east-1c"] // Only 1 Subnet per AZ
        transit_gateway_route_table = "spoke"                                                            # Default assoc/prop then default to false
      }
    }
    ## Managing route association of route tables of attached VPC's
    vpc_routes = {
      "prod" = {
        "private" = {
          destination_cidr_block = [
            "10.16.0.0/16", # TEST2
            "10.17.0.0/16"  # TEST3
          ]
        }
        "public" = {
          destination_cidr_block = [
            "10.16.0.0/16", # TEST2
            "10.17.0.0/16"  # TEST3
          ]
        }
      }
      "dev" = {
        "private" = {
          destination_cidr_block = [
            "10.15.0.0/16", # TEST1
            "10.17.0.0/16"  # TEST3
          ]
        }
        "public" = {
          destination_cidr_block = [
            "10.15.0.0/16", # TEST1
            "10.17.0.0/16"  # TEST3
          ]
        }
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
ram_principals                        = ["123456789012"]
enable_auto_accept_shared_attachments = true
```


</details>


### VPC attachments
Map keys (`prod`, `dev`, …) must match VPC keys from the VPC wrapper. `subnet_ids` use the same logical names as subnet keys (e.g. `private-us-east-1a`). Set `transit_gateway_route_table` to a `route_tables` key to associate the attachment with that named table; the attachment's default-table association/propagation then default to `false`. Without it, the attachment uses the AWS default tables (`transit_gateway_default_route_table_association` / `_propagation`, default `true`).


<details><summary>Two attachments on named tables (from examples/complete)</summary>

```hcl
vpc_attachments = {
  "prod" = {
    subnet_ids                  = ["private-us-east-1a", "private-us-east-1b", "private-us-east-1c"]
    dns_support                 = true
    ipv6_support                = false
    transit_gateway_route_table = "shared"
  }
  "dev" = {
    subnet_ids                  = ["private-us-east-1a", "private-us-east-1b", "private-us-east-1c"]
    transit_gateway_route_table = "spoke"
  }
}
```


</details>


### Default vs extra vs named TGW route tables
A Transit Gateway always has an **AWS default** route table. `enable_default_route_table_association` / `enable_default_route_table_propagation` only enable or disable auto-use of that table for new attachments; they do not create it.

`create_tgw_routes` is the nested `terraform-aws-modules/transit-gateway` flag. When `true` (default) it creates **one extra** table (tagged like the TGW) and associates/propagates only the VPC attachments that set `transit_gateway_default_route_table_association` / `_propagation` to `false`. Attachments that keep those flags `true` stay on the AWS default table. In a spoke account (`create_tgw = false`) it has no effect.

`route_tables` is the wrapper alternative: one named table per key (`${common_name}-tgw-rt-<key>`) with its own associations, propagations and static routes. It requires `create_tgw_routes = false` (plan fails otherwise) so the extra table cannot also claim the same attachments. On an existing TGW that removes the extra table; see **Migrating an existing TGW to route_tables** in the notes. The pre-route_tables layout is kept for reference in `examples/legacy-tgw-routes`.



### Named TGW route tables
`route_tables` creates named TGW route tables (`${common_name}-tgw-rt-<key>`). Set `create = false` to use an existing table on the same TGW instead, found by `id` or by `name` (Name tag; default `${common_name}-tgw-rt-<key>`). Lookups only work in the TGW owner account.

**Associate (which table an attachment uses to send traffic)**
- Local VPC: `vpc_attachments.<vpc>.transit_gateway_route_table = "<key>"`.
- VPN or a VPC in another account: `attachments.<name>.associate = "<key>"`. Discover with `name` (Name tag, only if the attachment was created in this account), `owner_id` (spoke account ID; required for cross-account VPCs because their tags are not visible to the TGW owner), `resource_id` (VPC ID), or `id` (`tgw-attach-…`). `resource_type` defaults to `vpc`; use `vpn` for VPN attachments.
- VPN created by the VPN wrapper in the same stack: associate it from `vpn_parameters` (`transit_gateway_route_table`, `transit_gateway_propagations`, `transit_gateway_static_route_tables`) instead of `attachments`.
- `replace_existing_association = true`, so an attachment already on the default table can move.

**Propagate (which prefixes a table learns)**
- `route_tables.<key>.propagations = ["prod", "spoke", "vpn-01"]`. Keys must exist in `vpc_attachments` or `attachments`. Propagation does not move the attachment; it only advertises that attachment's CIDRs into the named table.

**Static routes and blackholes**
- `route_tables.<key>.static_routes = [{ destination_cidr_block = "0.0.0.0/0", attachment = "prod" }, { destination_cidr_block = "10.99.0.0/16", blackhole = true }]`.

AWS RAM cannot share TGW route tables; associations stay in the TGW owner account. Spoke stacks do not reference named tables.


<details><summary>Named tables and attachment association</summary>

```hcl
create_tgw_routes                      = false
enable_default_route_table_association = false
enable_default_route_table_propagation = false

attachments = {
  vpn-01 = { resource_type = "vpn", name = "example-vpn-01", associate = "hybrid" }
  spoke  = { owner_id = "123456789012", associate = "spoke" }
}

vpc_attachments = {
  prod = {
    subnet_ids                  = ["private-a", "private-b", "private-c"]
    transit_gateway_route_table = "shared"
  }
}

route_tables = {
  shared = { propagations = ["spoke", "vpn-01"] }
  hybrid = { propagations = ["prod", "spoke"] }
  spoke = {
    propagations = ["vpn-01", "prod"]
    static_routes = [
      { destination_cidr_block = "0.0.0.0/0", attachment = "prod" },
      { destination_cidr_block = "10.99.0.0/16", blackhole = true },
    ]
  }
  existing = { create = false, name = "example-tgw-rt-existing", propagations = ["prod"] }
}
```


</details>


### Spoke account attachments
In the spoke account set `create_tgw = false`; the shared TGW is found by `amazon_side_asn`. Declare `vpc_attachments` and `vpc_routes` only. Do not set `transit_gateway_default_route_table_association` / `_propagation` there: AWS ignores them for a TGW owned by another account and the provider always reads `true`. Association and propagation are configured in the owner account with `attachments.<name>.owner_id`. See `examples/spoke-account`.


<details><summary>Spoke VPC attachment (from examples/spoke-account)</summary>

```hcl
tgw_parameters = {
  "tgw-01" = {
    create_tgw      = false
    amazon_side_asn = "64512"

    vpc_attachments = {
      "prod" = {
        subnet_ids   = ["private-us-east-1a", "private-us-east-1b", "private-us-east-1c"]
        dns_support  = true
        ipv6_support = false
      }
    }

    vpc_routes = {
      "prod" = {
        "private" = { destination_cidr_block = ["10.20.0.0/16", "10.60.0.0/16"] }
        "public"  = { destination_cidr_block = ["10.20.0.0/16", "10.60.0.0/16"] }
      }
    }
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
The complete example documents optional keys as comments (`create_tgw`, `description`, `amazon_side_asn`, default association/propagation, multicast, VPN ECMP, DNS, SG referencing, encryption, `region`, `transit_gateway_cidr_blocks`, `transit_gateway_route_table_id`, `ram_allow_external_principals`, `ram_name`). Keys shared by every gateway can be set once in `tgw_defaults`.





## 📑 Inputs
| Name                                                            | Description                                                                                                                 | Type           | Default                                    | Required  |
| --------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- | -------------- | ------------------------------------------ | --------- |
| create_tgw                                                      | Whether to create the Transit Gateway. `false` uses an existing (shared) TGW found by `amazon_side_asn`.                    | `bool`         | `true`                                     | no        |
| name                                                            | Resource name identifier.                                                                                                   | `string`       | `"${local.common_name}-${each.key}"`       | no        |
| description                                                     | Transit Gateway description.                                                                                                | `string`       | `null`                                     | no        |
| amazon_side_asn                                                 | Amazon-side ASN; also the lookup filter when `create_tgw = false`.                                                          | `string`       | `"64512"`                                  | no        |
| create_tgw_routes                                               | Nested extra TGW route table. Does not create the AWS default table. Must be `false` when `route_tables` is set.            | `bool`         | `true`                                     | no        |
| enable_default_route_table_association                          | Auto-associate attachments with the default route table. `false` → `true` replaces the TGW.                                 | `bool`         | `true`, or `false` with `route_tables`     | no        |
| enable_default_route_table_propagation                          | Auto-propagate attachments to the default route table. `false` → `true` replaces the TGW.                                   | `bool`         | `true`, or `false` with `route_tables`     | no        |
| enable_auto_accept_shared_attachments                           | Auto-accept shared attachment requests.                                                                                     | `bool`         | `false`                                    | no        |
| enable_vpn_ecmp_support                                         | VPN ECMP support.                                                                                                           | `bool`         | `true`                                     | no        |
| enable_multicast_support                                        | Multicast support.                                                                                                          | `bool`         | `false`                                    | no        |
| enable_dns_support                                              | DNS support on the TGW.                                                                                                     | `bool`         | `true`                                     | no        |
| enable_sg_referencing_support                                   | Security group referencing on the TGW.                                                                                      | `bool`         | `false`                                    | no        |
| enable_encryption_support                                       | Encryption support on the TGW.                                                                                              | `bool`         | `false`                                    | no        |
| region                                                          | AWS region for the TGW and wrapper-owned resources.                                                                         | `string`       | `metadata.aws_region` then provider        | no        |
| transit_gateway_cidr_blocks                                     | TGW CIDR blocks (IPv4 /24+ or IPv6 /64+).                                                                                   | `list(string)` | `[]`                                       | no        |
| transit_gateway_route_table_id                                  | Existing route table ID when reusing a TGW.                                                                                 | `string`       | `null`                                     | no        |
| share_tgw                                                       | Share the TGW through RAM.                                                                                                  | `bool`         | `false`                                    | no        |
| ram_name                                                        | RAM resource share name.                                                                                                    | `string`       | `"${local.common_name}-${each.key}"`       | no        |
| ram_allow_external_principals                                   | Allow principals outside the organization.                                                                                  | `bool`         | `false`                                    | no        |
| ram_principals                                                  | Account IDs, Organization ARNs, or OU ARNs.                                                                                 | `list(string)` | `[]`                                       | no        |
| ram_resource_share_arn                                          | Existing RAM share ARN.                                                                                                     | `string`       | `""`                                       | no        |
| tags                                                            | Tags for all resources (upstream `tags`).                                                                                   | `map(string)`  | `local.common_tags`                        | no        |
| vpc_attachments                                                 | Map of VPC attachments keyed by VPC key; `vpc_id` and `subnet_ids` are resolved from `vpc_parameter`.                       | `any`          | `{}`                                       | no        |
| vpc_attachments.subnet_ids                                      | Subnet keys, one per AZ.                                                                                                    | `list(string)` | —                                          | yes       |
| vpc_attachments.transit_gateway_route_table                     | `route_tables` key to associate with. Also defaults the two flags below to `false`.                                         | `string`       | `null`                                     | no        |
| vpc_attachments.transit_gateway_default_route_table_association | Associate with the TGW default table. Owner account only.                                                                   | `bool`         | `true`                                     | no        |
| vpc_attachments.transit_gateway_default_route_table_propagation | Propagate to the TGW default table. Owner account only.                                                                     | `bool`         | `true`                                     | no        |
| vpc_attachments.dns_support                                     | DNS support on the attachment.                                                                                              | `bool`         | `true`                                     | no        |
| vpc_attachments.ipv6_support                                    | IPv6 support on the attachment.                                                                                             | `bool`         | `false`                                    | no        |
| vpc_attachments.appliance_mode_support                          | Appliance mode (symmetric routing for inspection VPCs).                                                                     | `bool`         | `false`                                    | no        |
| vpc_attachments.security_group_referencing_support              | Security group referencing on the attachment.                                                                               | `bool`         | `true`                                     | no        |
| vpc_attachments.tags                                            | Attachment tags (Name is always set).                                                                                       | `map(string)`  | `local.common_tags`                        | no        |
| vpc_routes                                                      | **Wrapper-only:** `vpc_routes.<vpc>.<route_table>.destination_cidr_block` → `aws_route` to TGW.                             | `any`          | `{}`                                       | no        |
| route_tables                                                    | **Wrapper-only:** named TGW route tables keyed by name. Requires `create_tgw_routes = false`.                               | `any`          | `{}`                                       | no        |
| route_tables.propagations                                       | `vpc_attachments` / `attachments` keys that propagate into this table.                                                      | `list(string)` | `[]`                                       | no        |
| route_tables.static_routes                                      | `{ destination_cidr_block, attachment }` or `{ destination_cidr_block, blackhole = true }`.                                 | `list(any)`    | `[]`                                       | no        |
| route_tables.create                                             | `false` uses an existing table on the same TGW (by `id` or `name`).                                                         | `bool`         | `true` (`false` when `create_tgw = false`) | no        |
| route_tables.id                                                 | Existing table ID when `create = false`.                                                                                    | `string`       | `null`                                     | no        |
| route_tables.name                                               | Name tag (created table) or lookup name (`create = false`).                                                                 | `string`       | `"${local.common_name}-tgw-rt-<key>"`      | no        |
| route_tables.tags                                               | Extra tags for a created table.                                                                                             | `map(string)`  | `{}`                                       | no        |
| attachments                                                     | **Wrapper-only:** existing attachments (VPN, other accounts) discovered for `associate` / `propagations` / `static_routes`. | `any`          | `{}`                                       | no        |
| attachments.resource_type                                       | Attachment type filter (`vpc`, `vpn`, …).                                                                                   | `string`       | `"vpc"`                                    | no        |
| attachments.id / name / owner_id / resource_id                  | Lookup filter; at least one is required. `name` only works for attachments created in the owner account.                    | `string`       | `null`                                     | yes (one) |
| attachments.associate                                           | `route_tables` key to associate the attachment with.                                                                        | `string`       | `null`                                     | no        |







## ⚠️ Important Notes
- ⚠️ **TGW replacement**: changing `enable_default_route_table_association` or `enable_default_route_table_propagation` from `false` to `true` replaces the Transit Gateway (`true` → `false` is an in-place update). Both default to `true`, or `false` when `route_tables` is set, so removing `route_tables` later also flips them. Set both explicitly and keep them fixed once the TGW exists.
- ⚠️ **Cross-account deploy and destroy order**: deploy the owner account (TGW, RAM share), then the spoke stacks, then the owner again with `attachments.<name>.owner_id` to associate/propagate the new attachments. Destroy spokes first. A discovered attachment that no longer exists does not block `destroy`; a normal plan fails with "TGW attachment … not found" until it is removed from `attachments` and `route_tables`.
- ⚠️ **Default-table flags in spoke accounts**: `vpc_attachments.*.transit_gateway_default_route_table_association` / `_propagation` only take effect in the TGW owner account. In a spoke (`create_tgw = false`) omit them; `false` shows a perpetual in-place diff.
- ⚠️ **Migrating an existing TGW to route_tables**: setting `create_tgw_routes = false` destroys the nested extra table (`module.wrapper_tgw["<tgw>"].aws_ec2_transit_gateway_route_table.this[0]`) and its associations/propagations. Attachments on it lose routing until they are associated with a named table, so plan in a window. To keep that table, add a `route_tables.<key>` entry and `terraform state mv` it to `aws_ec2_transit_gateway_route_table.this["<tgw>/<key>"]` (or a `moved` block in the caller); then declare its associations and propagations under `route_tables`. `vpc_attachments.*.tgw_routes` is not forwarded to the upstream module; declare those routes as `route_tables.<key>.static_routes`.
- ⚠️ **VPN in the same stack**: wire a VPN created by the VPN wrapper from `vpn_parameters`, not from `attachments`. An `attachments` lookup fails on the first apply because the VPN attachment does not exist yet, and listing it in both places associates it twice.
- ℹ️ **Requirements**: AWS provider `>= 6.28`. Nested module `terraform-aws-modules/transit-gateway/aws` `3.3.1`; resource addresses are the same as with 2.12.1.
- ℹ️ **Existing Transit Gateway**: when `create_tgw = false`, the TGW is found by `options.amazon-side-asn` (default `64512`). Use a unique ASN if several gateways are visible to the account.
- ℹ️ **Region**: `region` on a TGW entry or `tgw_defaults.region` overrides `metadata.aws_region`, then the AWS provider region.
- ℹ️ **Subnet and route table keys**: `vpc_parameter.subnets` keys must be `{vpc_key}-{subnet_group}-{az_key}` (same as the VPC wrapper). `vpc_parameter.route_tables` keys must be `{vpc_key}-{route_table_name}`.
- ℹ️ **Security group referencing defaults**: `enable_sg_referencing_support` defaults to `false` on the TGW and `security_group_referencing_support` to `true` on VPC attachments. These are the AWS defaults, so gateways and attachments created with 0.1.0 (upstream 2.x) plan with no changes.
- ℹ️ **tgw_defaults**: merged under every `tgw_parameters` entry (shallow merge), so any TGW-level key can be set once for all gateways.
- 🔒 **RAM and AWS Organizations**: to share the Transit Gateway with organization accounts without invitations, turn on **Resource Access Manager → Settings → Enable sharing with AWS Organizations** in the organization's management account. The organization must have **all features** enabled.



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