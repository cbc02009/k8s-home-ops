module "cf_domain_hardware" {
  source     = "./modules/cf_domain"
  domain     = "ctec.run"
  account_id = cloudflare_account.cbc02009.id
  dns_entries = [
    {
      name  = "ipv4"
      value = local.home_ipv4
    },
    # Generic settings
    {
      name  = "_dmarc"
      value = "v=DMARC1; p=none; rua=mailto:postmaster@ctec.run; ruf=mailto:postmaster@ctec.run; fo=1;"
      type  = "TXT"
    },
    # Proton settings
    {
      id       = "protonmail_verification"
      name     = "@"
      value    = "protonmail-verification=3060333aaf4ebaae4f1faf707ae7669f88d6808c"
      type     = "TXT"
    },
    {
      id       = "fastmail_mx_1"
      name     = "@"
      priority = 10
      value    = "in1-smtp.messagingengine.com"
      type     = "MX"
    },
    {
      id       = "fastmail_mx_2"
      name     = "@"
      priority = 20
      value    = "in2-smtp.messagingengine.com"
      type     = "MX"
    },
    {
      id      = "fastmail_dkim_1"
      name    = "fm1._domainkey"
      value   = "fm1.ctec.run.dkim.fmhosted.com"
      type    = "CNAME"
      proxied = false
    },
    {
      id      = "fastmail_dkim_2"
      name    = "fm2._domainkey"
      value   = "fm2.ctec.run.dkim.fmhosted.com"
      type    = "CNAME"
      proxied = false
    },
    {
      id      = "fastmail_dkim_3"
      name    = "fm3._domainkey"
      value   = "fm3.ctec.run.dkim.fmhosted.com"
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
