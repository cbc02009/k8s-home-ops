terraform {
    backend "pg" {
    conn_str = "postgres://10.6.0.20/terraform"
    schema_name = "cloudflare"
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.16.0"
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

provider "cloudflare" {
  email   = module.secret_cf.fields.email
  api_key = module.secret_cf.fields.api_key
}
