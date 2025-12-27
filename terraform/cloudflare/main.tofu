terraform {
#   backend "s3" {
#     bucket                      = "terraform"
#     key                         = "cloudflare/state.tfstate"
#     skip_credentials_validation = true
#     skip_metadata_api_check     = true
#     skip_region_validation      = true
#   }

    backend "pg" {
    conn_str = "postgres://10.6.0.20/terraform"
    schema_name = "cloudflare"
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.52.5"
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
