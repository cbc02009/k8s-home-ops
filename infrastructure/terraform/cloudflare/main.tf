terraform {
  # cloud {
  #   organization = "kokoro-wtf"
  #   workspaces {
  #     name = "arpa-home-cloudflare"
  #   }
  # }

  backend "pg" {
    conn_str = "postgres://10.6.0.20/terraform"
    schema_name = "cloudflare"
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.12.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.5.0"
    }
  }
}

module "secret_cf" {
  # Remember to export OP_CONNECT_HOST and OP_CONNECT_TOKEN
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "k8s-home-ops"
  item   = "cloudflare"
}

# Obtain current home IP address
data "http" "ipv4_lookup_raw" {
  url = "http://ipv4.icanhazip.com"
}
