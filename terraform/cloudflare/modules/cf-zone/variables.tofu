variable "zone_name" {
  description = "Cloudflare zone (domain) name, e.g. ctec.run."
  type        = string
}

variable "records" {
  description = "Map of DNS records to manage in this zone. name is relative to the zone (\"@\" for the apex)."
  type = map(object({
    type     = string
    name     = string
    content  = string
    ttl      = optional(number, 1)
    proxied  = optional(bool)
    priority = optional(number)
    comment  = optional(string)
  }))
}
