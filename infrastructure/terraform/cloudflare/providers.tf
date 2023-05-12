provider "cloudflare" {
  email   = module.onepassword_item_cloudflare.fields["email"]
  api_key = module.onepassword_item_cloudflare.fields["api_key"]
}
