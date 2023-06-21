terraform {
  cloud {
    hostname     = "app.terraform.io"
    organization = "kokoro-wtf"
    workspaces {
      name = "arpa-home-cloudflare"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.8.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.0"
    }
  }
}

# Obtain current home IP address
data "http" "ipv4_lookup_raw" {
  url = "http://ipv4.icanhazip.com"
}

module "onepassword_item_cloudflare" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Services"
  item   = "cloudflare"
}
