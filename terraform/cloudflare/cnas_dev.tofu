# cnas.dev — hand-managed DNS records (module: cf-zone).
# Generated from live Cloudflare inventory; external-dns, cert-manager and
# stale dated DKIM selectors are intentionally NOT managed here.

module "cnas_dev" {
  source = "./modules/cf-zone"

  zone_name = "cnas.dev"

  records = {
  }
}
