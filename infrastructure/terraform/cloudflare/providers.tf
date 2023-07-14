provider "cloudflare" {
  email   = data.doppler_secrets.this.map.EMAIL
  api_key = data.doppler_secrets.this.map.API_KEY
}
