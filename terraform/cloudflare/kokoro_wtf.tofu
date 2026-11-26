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

# Import blocks — live record IDs from the Cloudflare API (2026-11-26).
import {
  to = module.kokoro_wtf.cloudflare_dns_record.records["dkim-1"]
  id = "1ebf7a0d3382dabeaefd3adfe3da6981"
}
import {
  to = module.kokoro_wtf.cloudflare_dns_record.records["dkim-2"]
  id = "743f424d15cc880263a2cf525bf25abc"
}
import {
  to = module.kokoro_wtf.cloudflare_dns_record.records["dkim-3"]
  id = "b14ece1c3e02b42bc0917c9cb546a76c"
}
import {
  to = module.kokoro_wtf.cloudflare_dns_record.records["ipv4"]
  id = "70801b0877eddede67cd6e5d85b01b6f"
}
import {
  to = module.kokoro_wtf.cloudflare_dns_record.records["k8s_schemas_pages"]
  id = "d1a57e94639c6b3b4c8d21ac19dafa3e"
}
import {
  to = module.kokoro_wtf.cloudflare_dns_record.records["mailmx-1"]
  id = "2b4bf81c3b51fc0d279032fed795f33f"
}
import {
  to = module.kokoro_wtf.cloudflare_dns_record.records["mailmx-2"]
  id = "2dbe9c225c4ad2d12f77a5cd309ec24b"
}
import {
  to = module.kokoro_wtf.cloudflare_dns_record.records["portal"]
  id = "68d0f384a819f830f502e6096fe34ed0"
}
import {
  to = module.kokoro_wtf.cloudflare_dns_record.records["txt_dmarc"]
  id = "e908b52f1224e9c0a699c758239f78a3"
}
import {
  to = module.kokoro_wtf.cloudflare_dns_record.records["txt_spf"]
  id = "eaf6087d2a0936c2dc2c0a2ff8ae19c5"
}
