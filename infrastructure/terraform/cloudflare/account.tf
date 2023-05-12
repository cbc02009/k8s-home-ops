resource "cloudflare_account" "cbc02009" {
  name              = "cbc02009 Account"
  type              = "standard"
  enforce_twofactor = false
}
