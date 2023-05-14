resource "cloudflare_tunnel" "tunnel" {
  account_id = cloudflare_account.cbc02009.id
  name       = "home"
  secret     = module.onepassword_item_cloudflare.fields["tunnel_secret"]
}

resource "cloudflare_tunnel_config" "config" {
  account_id = cloudflare_account.cbc02009.id
  tunnel_id  = cloudflare_tunnel.tunnel.id

  config {
      ingress_rule {
          hostname = "*.kokoro.wtf"
          service  = "https://ingress-nginx-controller.network.svc.cluster.local:443"
      }
      ingress_rule {
          service = "http_status:404"
      }
  }
}
