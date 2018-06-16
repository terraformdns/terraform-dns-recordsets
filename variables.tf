
variable "zone_name" {
  type        = "string"
  description = "Name of the zone where the given recordsets are to be managed."
}

variable "recordsets" {
  type = list(object({
    name    = string
    type    = string
    ttl     = number
    records = list(string)
  }))
  description = "List of DNS record objects to manage, in the standard terraformdns structure."
}
