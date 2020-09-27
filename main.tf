
terraform {
  required_version = ">= 0.12.0"
  required_providers {
    dns = ">= 2.0.0"
  }
}

module "normalize" {
  source = "terraformdns/normalize-recordsets/template"

  target_zone_name = var.zone_name
  recordsets       = var.recordsets
}

# Since the DNS provider uses a separate resource type for each DNS record
# type, we'll need to split up our input list.
locals {
  # For consistency with modules for other providers, we take a hostname
  # without a trailing period as input, but the underlying provider actually
  # requires it so we'll add it now.
  zone_name = "${var.zone_name}."

  recordsets       = { for rs in module.normalize.normalized : rs.type => rs... }
  a_recordsets     = lookup(local.recordsets, "A", [])
  aaaa_recordsets  = lookup(local.recordsets, "AAAA", [])
  cname_recordsets = lookup(local.recordsets, "CNAME", [])
  ns_recordsets    = lookup(local.recordsets, "NS", [])
  ptr_recordsets   = lookup(local.recordsets, "PTR", [])

  # Some of the resources only deal with one record at a time, and so we need
  # to flatten these.
  cname_records = flatten([
    for rs in local.cname_recordsets : [
      for r in rs.records : {
        name = rs.name
        type = rs.type
        ttl  = rs.ttl
        data = r
      }
    ]
  ])
  ptr_records = flatten([
    for rs in local.ptr_recordsets : [
      for r in rs.records : {
        name = rs.name
        type = rs.type
        ttl  = rs.ttl
        data = r
      }
    ]
  ])
}

resource "dns_a_record_set" "this" {
  for_each = { for rs in local.a_recordsets : rs.name => rs }

  zone = local.zone_name

  name      = coalesce(each.value.name, "@")
  ttl       = each.value.ttl
  addresses = each.value.records
}

resource "dns_aaaa_record_set" "this" {
  for_each = { for rs in local.aaaa_recordsets : rs.name => rs }

  zone = local.zone_name

  name      = coalesce(each.value.name, "@")
  ttl       = each.value.ttl
  addresses = each.value.records
}

resource "dns_cname_record" "this" {
  for_each = { for r in local.cname_records : "${r.name}:${r.data}" => r }

  zone = local.zone_name

  name  = coalesce(each.value.name, "@")
  ttl   = each.value.ttl
  cname = each.value.data
}

resource "dns_ns_record_set" "this" {
  for_each = { for rs in local.ns_recordsets : rs.name => rs }

  zone = local.zone_name

  name        = coalesce(each.value.name, "@")
  ttl         = each.value.ttl
  nameservers = each.value.records
}

resource "dns_ptr_record" "this" {
  for_each = { for r in local.ptr_records : "${r.name}:${r.data}" => r }

  zone = local.zone_name

  name = coalesce(each.value.name, "@")
  ttl  = each.value.ttl
  ptr  = each.value.data
}
