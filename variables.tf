
variable "zone_name" {
  type        = string
  description = "Name of the zone where the given recordsets are to be managed."
}

variable "recordsets" {
  type = set(object({
    name    = string
    type    = string
    ttl     = number
    records = set(string)
  }))
  description = "Set of DNS record objects to manage, in the standard terraformdns structure."

  validation {
    condition = length([
      for rs in var.recordsets : true
      if ! contains(["A", "AAAA", "CNAME", "NS", "PTR"], rs.type)
    ]) == 0
    error_message = "Due to the design of the underlying hashicorp/dns provider, only the following recordset types are supported: A, AAAA, CNAME, NS, PTR."
  }
}
