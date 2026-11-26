# Generic per-zone DNS management module for Cloudflare.
#
# Resolves the zone by name via the API (no hardcoded zone IDs) and manages
# exactly the records passed in `records`. Records owned by other systems
# (external-dns, cert-manager) must NOT be added here — those managers own
# their own records and tofu taking them over would fight them.

locals {
  zone_id = data.cloudflare_zone.zone.zone_id

  fqdns = {
    for key, rec in var.records : key => (
      rec.name == "@" ? var.zone_name : "${rec.name}.${var.zone_name}"
    )
  }
}

data "cloudflare_zone" "zone" {
  filter = {
    name = var.zone_name
  }
}

resource "cloudflare_dns_record" "records" {
  for_each = var.records

  zone_id  = local.zone_id
  name     = local.fqdns[each.key]
  type     = each.value.type
  content  = each.value.content
  ttl      = each.value.ttl
  proxied  = try(each.value.proxied, null)
  priority = try(each.value.priority, null)
  comment  = try(each.value.comment, null)
}

output "zone_id" {
  description = "Resolved Cloudflare zone ID."
  value       = local.zone_id
}

output "record_ids" {
  description = "Live record IDs per record key (populated once imported/applied)."
  value       = { for key, rec in cloudflare_dns_record.records : key => rec.id }
}
