terraform {
    backend "pg" {
    conn_str = "postgres://10.6.0.20/terraform"
    schema_name = "authentik"
  }

  required_providers {
    garage = {
      source  = "registry.terraform.io/jkossis/garage"
      version = "1.0.4"
    }
  }
}

module "onepassword_item_garage" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Homelab"
  item   = "garage"
}

provider "garage" {
  endpoint   = "https://s3-api.cnas.dev"
  token     = module.onepassword_item_garage.fields.admin_token
}
