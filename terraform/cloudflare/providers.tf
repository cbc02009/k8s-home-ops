provider "cloudflare" {
  email   = module.secret_cf.fields.email
  api_key = module.secret_cf.fields.api_key
}
