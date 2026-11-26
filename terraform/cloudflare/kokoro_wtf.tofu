# kokoro.wtf — hand-managed DNS records (module: cf-zone).
# Generated from live Cloudflare inventory; external-dns, cert-manager and
# stale dated DKIM selectors are intentionally NOT managed here.

module "kokoro_wtf" {
  source = "./modules/cf-zone"

  zone_name = "kokoro.wtf"

  records = {
    dkim-1 = {
      name    = "fm1._domainkey"
      type    = "CNAME"
      content = "fm1.kokoro.wtf.dkim.fmhosted.com"
      ttl     = 1
      proxied = false
    }
    dkim-2 = {
      name    = "fm2._domainkey"
      type    = "CNAME"
      content = "fm2.kokoro.wtf.dkim.fmhosted.com"
      ttl     = 1
      proxied = false
    }
    dkim-3 = {
      name    = "fm3._domainkey"
      type    = "CNAME"
      content = "fm3.kokoro.wtf.dkim.fmhosted.com"
      ttl     = 1
      proxied = false
    }
    ipv4 = {
      name    = "ipv4"
      type    = "A"
      content = "47.165.88.12"
      ttl     = 1
      proxied = false
    }
    k8s_schemas_pages = {
      name    = "k8s-schemas"
      type    = "CNAME"
      content = "k8s-schemas-1a0.pages.dev"
      ttl     = 1
      proxied = true
    }
    mailmx-1 = {
      name     = "@"
      type     = "MX"
      content  = "in1-smtp.messagingengine.com"
      ttl      = 1
      proxied  = false
      priority = 10
    }
    mailmx-2 = {
      name     = "@"
      type     = "MX"
      content  = "in2-smtp.messagingengine.com"
      ttl      = 1
      proxied  = false
      priority = 20
    }
    portal = {
      name    = "portal"
      type    = "CNAME"
      content = "ipv4.kokoro.wtf"
      ttl     = 1
      proxied = false
    }
    txt_dmarc = {
      name    = "_dmarc"
      type    = "TXT"
      content = "v=DMARC1; p=none; rua=mailto:postmaster@kokoro.wtf; ruf=mailto:postmaster@kokoro.wtf; fo=1;"
      ttl     = 1
      proxied = false
    }
    txt_spf = {
      name    = "@"
      type    = "TXT"
      content = "v=spf1 include:spf.messagingengine.com ?all"
      ttl     = 1
      proxied = false
    }
  }
}
