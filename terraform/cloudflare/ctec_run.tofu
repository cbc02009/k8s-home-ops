# ctec.run — hand-managed DNS records (module: cf-zone).
# Generated from live Cloudflare inventory; external-dns, cert-manager and
# stale dated DKIM selectors are intentionally NOT managed here.

module "ctec_run" {
  source = "./modules/cf-zone"

  zone_name = "ctec.run"

  records = {
    dkim-1 = {
      name    = "fm1._domainkey"
      type    = "CNAME"
      content = "fm1.ctec.run.dkim.fmhosted.com"
      ttl     = 43200
      proxied = false
    }
    dkim-2 = {
      name    = "fm2._domainkey"
      type    = "CNAME"
      content = "fm2.ctec.run.dkim.fmhosted.com"
      ttl     = 43200
      proxied = false
    }
    dkim-3 = {
      name    = "fm3._domainkey"
      type    = "CNAME"
      content = "fm3.ctec.run.dkim.fmhosted.com"
      ttl     = 43200
      proxied = false
    }
    mailmx-1 = {
      name     = "@"
      type     = "MX"
      content  = "in1-smtp.messagingengine.com"
      ttl      = 3600
      proxied  = false
      priority = 10
    }
    mailmx-2 = {
      name     = "@"
      type     = "MX"
      content  = "in2-smtp.messagingengine.com"
      ttl      = 3600
      proxied  = false
      priority = 20
    }
    root-a = {
      name    = "@"
      type    = "A"
      content = "47.165.88.12"
      ttl     = 60
      proxied = false
    }
    txt_dmarc = {
      name    = "@"
      type    = "TXT"
      content = "v=DMARC1; p=quarantine; pct=100; rua=mailto:postmaster@ctec.run; ruf=mailto:postmaster@ctec.run"
      ttl     = 43200
      proxied = false
    }
    txt_spf = {
      name    = "@"
      type    = "TXT"
      content = "v=spf1 include:spf.messagingengine.com -all"
      ttl     = 43200
      proxied = false
    }
  }
}
