terraform {

  backend "pg" {
    conn_str = "postgres://10.6.0.20/terraform"
    schema_name = "minio"
  }

  required_providers {
    minio = {
      source = "aminueza/minio"
      version = "3.3.0"
    }
  }
}

module "onepassword_item_minio" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "k8s-home-ops"
  item   = "minio"
}

provider "minio" {
  minio_server   = "s3.cnas.dev"
  minio_user     = module.onepassword_item_minio.fields.username
  minio_password = module.onepassword_item_minio.fields.password
  minio_ssl = true
}
