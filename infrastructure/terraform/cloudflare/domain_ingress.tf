module "cf_domain_ingress" {
  source     = "./modules/cf_domain"
  domain     = "kokoro.wtf"
  account_id = cloudflare_account.cbc02009.id
  dns_entries = [
    {
      name  = "ipv4"
      value = local.home_ipv4
    },
    {
      id      = "vpn"
      name    = module.secret_cf.fields.vpn_subdomain
      value   = "ipv4.kokoro.wtf"
      type    = "CNAME"
      proxied = false
    },
    # Generic settings
    {
      name  = "_dmarc"
      value = "v=DMARC1; p=none; rua=mailto:postmaster@kokoro.wtf; ruf=mailto:postmaster@kokoro.wtf; fo=1;"
      type  = "TXT"
    },

    # Proton Settings
    {
      id       = "protonmail_verification"
      name     = "@"
      value    = "protonmail-verification=a49f59e33698e4d4f71cac4c7c7a0074654fd7c7"
      type     = "TXT"
    },
    {
      id      = "fastmail_dkim_1"
      name    = "fm1._domainkey"
      value   = "fm1.kokoro.wtf.dkim.fmhosted.com"
      type    = "CNAME"
      proxied = false
    },
    {
      id      = "fastmail_dkim_2"
      name    = "fm2._domainkey"
      value   = "fm2.kokoro.wtf.dkim.fmhosted.com"
      type    = "CNAME"
      proxied = false
    },
    {
      id      = "fastmail_dkim_3"
      name    = "fm3._domainkey"
      value   = "fm3.kokoro.wtf.dkim.fmhosted.com"
      type    = "CNAME"
      proxied = false
    },
    {
      id    = "fastmail_spf"
      name  = "@"
      value = "v=spf1 include:spf.messagingengine.com ?all"
      type  = "TXT"
    }
  ]
}

# Allow Flux Webhook to access zone
# resource "cloudflare_filter" "cf_domain_ingress_github_flux_webhook" {
#   zone_id     = module.cf_domain_ingress.zone_id
#   description = "Allow GitHub flux API"
#   expression  = "(ip.geoip.asnum eq 36459 and http.host eq \"flux-receiver.kokoro.wtf\")"
# }

# resource "cloudflare_firewall_rule" "cf_domain_ingress_github_flux_webhook" {
#   zone_id     = module.cf_domain_ingress.zone_id
#   description = "Allow GitHub flux API"
#   filter_id   = cloudflare_filter.cf_domain_ingress_github_flux_webhook.id
#   action      = "allow"
#   priority    = 1
# }

# # Block Plex notifications (prevents cloudflared container spam)
# resource "cloudflare_filter" "plex_notifications" {
#   zone_id     = module.cf_domain_ingress.zone_id
#   description = "Expression to block Plex notifications"
#   expression  = "(http.host eq \"plex.kokoro.wtf\" and http.request.uri.path contains \"/:/eventsource/notifications\")"
# }

# resource "cloudflare_firewall_rule" "plex_notifications" {
#   zone_id     = module.cf_domain_ingress.zone_id
#   description = "Firewall rule to block Plex notifications"
#   filter_id   = cloudflare_filter.plex_notifications.id
#   action      = "block"
# }
