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
      name    = data.doppler_secrets.this.map.VPN_SUBDOMAIN
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
    # Fastmail settings
    {
      id       = "protonmail_mx_1"
      name     = "@"
      priority = 10
      value    = "mail.protonmail.ch"
      type     = "MX"
    },
    {
      id       = "protonmail_mx_2"
      name     = "@"
      priority = 20
      value    = "mailsec.protonmail.ch"
      type     = "MX"
    },
    {
      id      = "protonmail_dkim_1"
      name    = "protonmail1._domainkey"
      value   = "protonmail.domainkey.dyjrbchw73q7udksl2ucl4epepdg6tayyfi3ltddq2zxrtdg5j74a.domains.proton.ch."
      type    = "CNAME"
      proxied = false
    },
    {
      id      = "protonmail_dkim_2"
      name    = "protonmail2._domainkey"
      value   = "protonmail2.domainkey.dyjrbchw73q7udksl2ucl4epepdg6tayyfi3ltddq2zxrtdg5j74a.domains.proton.ch."
      type    = "CNAME"
      proxied = false
    },
    {
      id      = "protonmail_dkim_3"
      name    = "protonmail3._domainkey"
      value   = "protonmail3.domainkey.dyjrbchw73q7udksl2ucl4epepdg6tayyfi3ltddq2zxrtdg5j74a.domains.proton.ch."
      type    = "CNAME"
      proxied = false
    },
    {
      id    = "protonmail_spf"
      name  = "@"
      value = "v=spf1 include:_spf.protonmail.ch mx ~all"
      type  = "TXT"
    }
  ]
}

# Allow Flux Webhook to access zone
resource "cloudflare_filter" "cf_domain_ingress_github_flux_webhook" {
  zone_id     = module.cf_domain_ingress.zone_id
  description = "Allow GitHub flux API"
  expression  = "(ip.geoip.asnum eq 36459 and http.host eq \"flux-receiver.kokoro.wtf\")"
}

resource "cloudflare_firewall_rule" "cf_domain_ingress_github_flux_webhook" {
  zone_id     = module.cf_domain_ingress.zone_id
  description = "Allow GitHub flux API"
  filter_id   = cloudflare_filter.cf_domain_ingress_github_flux_webhook.id
  action      = "allow"
  priority    = 1
}

# Block Plex notifications (prevents cloudflared container spam)
resource "cloudflare_filter" "plex_notifications" {
  zone_id     = module.cf_domain_ingress.zone_id
  description = "Expression to block Plex notifications"
  expression  = "(http.host eq \"plex.kokoro.wtf\" and http.request.uri.path contains \"/:/eventsource/notifications\")"
}

resource "cloudflare_firewall_rule" "plex_notifications" {
  zone_id     = module.cf_domain_ingress.zone_id
  description = "Firewall rule to block Plex notifications"
  filter_id   = cloudflare_filter.plex_notifications.id
  action      = "block"
}
