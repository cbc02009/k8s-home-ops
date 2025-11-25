terraform {
  # cloud {
  #   organization = "kokoro-wtf"
  #   workspaces {
  #     name = "arpa-home-authentik"
  #   }
  # }

    backend "pg" {
    conn_str = "postgres://10.6.0.20/terraform"
    schema_name = "authentik"
  }

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2025.10.0"
    }
  }
}

module "secret_authentik" {
  # Remember to export OP_CONNECT_HOST and OP_CONNECT_TOKEN
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "k8s-home-ops"
  item   = "authentik"
}

module "secret_immich" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "k8s-home-ops"
  item   = "immich"
}

module "secret_grafana" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "k8s-home-ops"
  item   = "grafana"
}

module "secret_mealie" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "k8s-home-ops"
  item   = "mealie"
}

module "secret_paperless" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "k8s-home-ops"
  item   = "paperless"
}

# module "secret_ocis" {
#   source = "github.com/bjw-s/terraform-1password-item?ref=main"
#   vault  = "k8s-home-ops"
#   item   = "ocis"
# }

provider "authentik" {
  url   = module.secret_authentik.fields["endpoint"]
  token = module.secret_authentik.fields["tf_token"]
}
