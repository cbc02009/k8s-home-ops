data "http" "ipv4" {
  url = "http://ipv4.icanhazip.com"
}

data "cloudflare_zone" "public_domain" {
  name = "kokoro.wtf"
}

resource "cloudflare_record" "public_domain_apex" {
  name    = "ipv4"
  zone_id = data.cloudflare_zone.public_domain.id
  value   = chomp(data.http.ipv4.response_body)
  proxied = true
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "public_domain_root" {
  name    = "kokoro.wtf"
  zone_id = data.cloudflare_zone.public_domain.id
  value   = "ipv4.kokoro.wtf"
  proxied = true
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "public_domain_www" {
  name    = "www"
  zone_id = data.cloudflare_zone.public_domain.id
  value   = "ipv4.kokoro.wtf"
  proxied = true
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "public_domain_public_cname" {
  name    = data.sops_file.secrets.data["cloudflare_unproxied_cname"]
  zone_id = data.cloudflare_zone.public_domain.id
  value   = "ipv4.kokoro.wtf"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_page_rule" "public_domain_plex_bypass" {
  zone_id  = data.cloudflare_zone.public_domain.id
  target   = "https://plex.kokoro.wtf./*"
  status   = "active"
  priority = 1

  actions {
    cache_level              = "bypass"
    rocket_loader            = "off"
    automatic_https_rewrites = "on"
  }
}

resource "cloudflare_page_rule" "public_domain_home_assistant_bypass" {
  zone_id  = data.cloudflare_zone.public_domain.id
  target   = "https://hass.kokoro.wtf./*"
  status   = "active"
  priority = 2

  actions {
    cache_level              = "bypass"
    rocket_loader            = "off"
    automatic_https_rewrites = "on"
  }
}

resource "cloudflare_page_rule" "public_domain_photos_bypass" {
  zone_id  = data.cloudflare_zone.public_domain.id
  target   = "https://photos.kokoro.wtf./*"
  status   = "active"
  priority = 3

  actions {
    cache_level              = "bypass"
    rocket_loader            = "off"
    automatic_https_rewrites = "on"
  }
}

resource "cloudflare_zone_settings_override" "public_domain_settings" {
  zone_id = data.cloudflare_zone.public_domain.id
  settings {
    ssl                      = "strict"
    always_use_https         = "on"
    min_tls_version          = "1.2"
    opportunistic_encryption = "on"
    tls_1_3                  = "zrt"
    automatic_https_rewrites = "on"
    universal_ssl            = "on"
    browser_check            = "on"
    challenge_ttl            = 1800
    privacy_pass             = "on"
    security_level           = "medium"
    brotli                   = "on"
    minify {
      css  = "on"
      js   = "on"
      html = "on"
    }
    rocket_loader       = "off"
    always_online       = "off"
    development_mode    = "off"
    http3               = "on"
    zero_rtt            = "on"
    ipv6                = "on"
    websockets          = "on"
    opportunistic_onion = "on"
    pseudo_ipv4         = "off"
    ip_geolocation      = "on"
    email_obfuscation   = "on"
    server_side_exclude = "on"
    hotlink_protection  = "off"
    security_header {
      enabled = false
    }
  }
}
