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

# Import blocks — live record IDs from the Cloudflare API (2026-11-26).
import {
  to = module.ctec_run.cloudflare_dns_record.records["dkim-1"]
  id = "fb587b1bd7773f67db3f1a0b77f13a6a"
}
import {
  to = module.ctec_run.cloudflare_dns_record.records["dkim-2"]
  id = "38ffd61f451e11e40582e119741beb89"
}
import {
  to = module.ctec_run.cloudflare_dns_record.records["dkim-3"]
  id = "5cf266c5bdf4e01a868d6f4c3c00fd35"
}
import {
  to = module.ctec_run.cloudflare_dns_record.records["mailmx-1"]
  id = "3b5bae99fe4ce78c639e0b4c5b91a446"
}
import {
  to = module.ctec_run.cloudflare_dns_record.records["mailmx-2"]
  id = "2c0d8092b0282c13c34266543e42e76a"
}
import {
  to = module.ctec_run.cloudflare_dns_record.records["root-a"]
  id = "353a20f1d8b8e7a2dc648ae7630ca769"
}
import {
  to = module.ctec_run.cloudflare_dns_record.records["txt_dmarc"]
  id = "d84cea1a918ba9841820608ec51f23cd"
}
import {
  to = module.ctec_run.cloudflare_dns_record.records["txt_spf"]
  id = "be265fe1840859f8a937ad02e19c5b3c"
}
