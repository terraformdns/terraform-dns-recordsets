
terraform {
  required_version = ">= 0.12.0"
  required_providers {
    dns = ">= 2.0.0"
  }
}

# Since the DNS provider uses a separate resource type for each DNS record
# type, we'll need to split up our input list.
locals {
  # For consistency with modules for other providers, we take a hostname
  # without a trailing period as input, but the underlying provider actually
  # requires it so we'll add it now.
  zone_name = "${var.zone_name}."

  recordsets       = {for rs in var.recordsets : rs.type => rs ...}
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

  # With just our list splitting technique above, records of unsupported types
  # would be silently ignored. The following two expressions ensure that
  # such records will produce an error message instead, albeit not a very
  # helpful one.
  supported_record_types = {
    A     = true
    AAAA  = true
    CNAME = true
    NS    = true
    PTR   = true
  }
  check_supported_types = [
    # The index operation here will fail if one of the records has
    # an unsupported type.
    for rs in var.recordsets : local.supported_record_types[rs.type]
  ]
}

resource "dns_a_record_set" "this" {
  count = length(local.a_recordsets)

  zone = local.zone_name

  name      = coalesce(local.a_recordsets[count.index].name, "@")
  ttl       = local.a_recordsets[count.index].ttl
  addresses = local.a_recordsets[count.index].records
}

resource "dns_aaaa_record_set" "this" {
  count = length(local.aaaa_recordsets)

  zone = local.zone_name

  name      = coalesce(local.aaaa_recordsets[count.index].name, "@")
  ttl       = local.aaaa_recordsets[count.index].ttl
  addresses = local.aaaa_recordsets[count.index].records
}

resource "dns_cname_record" "this" {
  count = length(local.cname_records)

  zone = local.zone_name

  name  = coalesce(local.cname_records[count.index].name, "@")
  ttl   = local.cname_records[count.index].ttl
  cname = local.cname_records[count.index].data
}

resource "dns_ns_record_set" "this" {
  count = length(local.ns_recordsets)

  zone = local.zone_name

  name        = coalesce(local.ns_recordsets[count.index].name, "@")
  ttl         = local.ns_recordsets[count.index].ttl
  nameservers = local.ns_recordsets[count.index].records
}

resource "dns_cname_record" "ptr" {
  count = length(local.ptr_records)

  zone = local.zone_name

  name = coalesce(local.ptr_records[count.index].name, "@")
  ttl  = local.ptr_records[count.index].ttl
  ptr  = local.ptr_records[count.index].data
}
