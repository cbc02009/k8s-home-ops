# GeoIP blocking
resource "cloudflare_filter" "countries" {
  count = var.enable_default_firewall_rules ? 1 : 0

  zone_id     = cloudflare_zone.zone.id
  description = "Expression to block all countries except NL/BE/DE"
  expression  = "(ip.geoip.country in {\"CN\" \"IN\" \"RU\"})"
}

resource "cloudflare_firewall_rule" "countries" {
  count = var.enable_default_firewall_rules ? 1 : 0

  zone_id     = cloudflare_zone.zone.id
  description = "Firewall rule to block all countries except NL/BE/DE"
  filter_id   = cloudflare_filter.countries[count.index].id
  action      = "block"
}

# Bots and threats

resource "cloudflare_filter" "bots_and_threats" {
  count = var.enable_default_firewall_rules ? 1 : 0

  zone_id     = cloudflare_zone.zone.id
  description = "Expression to block bots and threats determined by CF"
  expression  = "(cf.client.bot) or (cf.threat_score gt 14)"
}

resource "cloudflare_firewall_rule" "bots_and_threats" {
  count = var.enable_default_firewall_rules ? 1 : 0

  zone_id     = cloudflare_zone.zone.id
  description = "Firewall rule to block bots and threats determined by CF"
  filter_id   = cloudflare_filter.bots_and_threats[count.index].id
  action      = "block"
}

# Block Plex notifications (prevents cloudflared container spam)
resource "cloudflare_filter" "plex_notifications" {
  zone_id     = cloudflare_zone.zone.id
  description = "Expression to block Plex notifications"
  expression  = "(http.host eq \"plex.kokoro.wtf\" and http.request.uri.path contains \"/:/eventsource/notifications\")"
}
resource "cloudflare_firewall_rule" "plex_notifications" {
  zone_id     = cloudflare_zone.zone.id
  description = "Firewall rule to block Plex notifications"
  filter_id   = cloudflare_filter.plex_notifications.id
  action      = "block"
}
