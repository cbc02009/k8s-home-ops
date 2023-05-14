resource "cloudflare_account" "cbc02009" {
  name              = "cbc02009 account"
  type              = "standard"
  enforce_twofactor = false
}
