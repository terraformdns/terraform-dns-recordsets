# RFC 2136 DNS Recordsets Module

This module manages DNS recordsets via the DNS dynamic updates protocol
described in RFC 2136.

## Example Usage

```hcl
provider "dns" {
  update {
    server        = "192.0.2.12"
    key_name      = "example.com."
    key_algorithm = "hmac-md5"
    key_secret    = "3VwZXJzZWNyZXQ="
  }
}

module "dns_records" {
  source = "terraformdns/recordsets/dns"

  recordsets = [
    {
      name    = "www"
      type    = "A"
      ttl     = 3600
      records = [
        "192.0.2.56",
      ]
    },
  ]
}
```

## Compatibility

When using this module, always use a version constraint that constraints to at
least a single major version. Future major versions may have new or different
required arguments, and may use a different internal structure that could
cause recordsets to be removed and replaced by the next plan.

## Arguments

- `zone_name` is the name of the zone where the given recordsets are to be
  managed. This must be a fully-qualified name _without_ the trailing `.`.
- `recordsets` is a list of DNS recordsets in the standard `terraformdns`
  recordset format.

This module requires the `dns` provider, which must be configured for dynamic
updates using its `update` configuration block.

## Limitations

This module supports only the following DNS record types, due to limitations
of the underlying Terraform provider:

- `A` and `AAAA`
- `CNAME`
- `NS`
- `PTR`
