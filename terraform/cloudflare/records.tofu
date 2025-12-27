data "cloudflare_zone" "domain" {
    name = var.public_domain
}

locals {
  public_domain_zone = data.cloudflare_zone.domain.id
}

data "http" "ipv4" {
  url = "http://ipv4.icanhazip.com"
}

resource "cloudflare_record" "root" {
  name    = var.public_domain
  content = chomp(data.http.ipv4.response_body)
  ttl     = 60
  type    = "A"
  zone_id = local.public_domain_zone
}

resource "cloudflare_record" "external" {
  name    = "external"
  content = chomp(data.http.ipv4.response_body)
  ttl     = 60
  type    = "A"
  zone_id = local.public_domain_zone
}

resource "cloudflare_record" "dkim-1" {
  name    = "fm1._domainkey.${var.public_domain}"
  content = "fm1.${var.public_domain}.dkim.fmhosted.com"
  ttl     = 43200
  type    = "CNAME"
  zone_id = local.public_domain_zone
}

resource "cloudflare_record" "dkim-2" {
  name    = "fm2._domainkey.${var.public_domain}"
  content = "fm2.${var.public_domain}.dkim.fmhosted.com"
  ttl     = 43200
  type    = "CNAME"
  zone_id = local.public_domain_zone
}

resource "cloudflare_record" "dkim-3" {
  name    = "fm3._domainkey.${var.public_domain}"
  content = "fm3.${var.public_domain}.dkim.fmhosted.com"
  ttl     = 43200
  type    = "CNAME"
  zone_id = local.public_domain_zone
}

resource "cloudflare_record" "mailmx-1" {
  name     = var.public_domain
  content  = "in1-smtp.messagingengine.com"
  priority = 10
  type     = "MX"
  ttl      = 3600
  zone_id  = local.public_domain_zone
}

resource "cloudflare_record" "mailmx-2" {
  name     = var.public_domain
  content  = "in2-smtp.messagingengine.com"
  priority = 20
  ttl      = 3600
  type     = "MX"
  zone_id  = local.public_domain_zone
}

resource "cloudflare_record" "txt_spf" {
  name    = var.public_domain
  content = "v=spf1 include:spf.messagingengine.com -all"
  ttl     = 43200
  type    = "TXT"
  zone_id = local.public_domain_zone
}

resource "cloudflare_record" "txt_dmarc" {
  name    = var.public_domain
  content = "v=DMARC1; p=quarantine; pct=100; rua=mailto:postmaster@${var.public_domain}; ruf=mailto:postmaster@${var.public_domain}"
  type    = "TXT"
  ttl     = 43200
  zone_id = local.public_domain_zone
}
