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
    # {
    #   id      = "protonmail_dkim_1"
    #   name    = "protonmail._domainkey"
    #   value   = "protonmail.domainkey.dyhvzqp4p2xqazzrepen5x2ykwsbchouvlgb4rjl7phvtycq7xtwa.domains.proton.ch."
    #   type    = "CNAME"
    #   proxied = false
    # },
    # {
    #   id      = "protonmail_dkim_2"
    #   name    = "protonmail2._domainkey"
    #   value   = "protonmail2.domainkey.dyhvzqp4p2xqazzrepen5x2ykwsbchouvlgb4rjl7phvtycq7xtwa.domains.proton.ch."
    #   type    = "CNAME"
    #   proxied = false
    # },
    # {
    #   id      = "protonmail_dkim_3"
    #   name    = "protonmail3._domainkey"
    #   value   = "protonmail3.domainkey.dyhvzqp4p2xqazzrepen5x2ykwsbchouvlgb4rjl7phvtycq7xtwa.domains.proton.ch."
    #   type    = "CNAME"
    #   proxied = false
    # },
    {
      id = "postmark_dkim"
      name = "20240322033030pm._domainkey"
      value = "k=rsa;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCEyywwsPuQrCfQLqN7NPZYsgK+HWXODZUsx4WR/0s2ivZjUVenbEKHCQp8kjZ3xVjDh+FCftx2VruRDAUXcRDdt445+OL5B58+G1Dm+ccx0KsClSLnwvhw880bn39VYPsCZ6JQ1cJ2q52+F/HMZ+lYeOhSKlqjiwwfzqUiJpaVWQIDAQAB"
      type = "TXT"
      proxied = "false"
    },
    {
      id = "postmark_return_path"
      name = "pm-bounces"
      value = "pm.mtasv.net"
      type = "cname"
      proxied = "false"
    },
    {
      id    = "protonmail_spf"
      name  = "@"
      value = "v=spf1 include:_spf.protonmail.ch mx ~all"
      type  = "TXT"
    }
  ]
}
