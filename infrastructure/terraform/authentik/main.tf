terraform {
  cloud {
    organization = "kokoro-wtf"
    workspaces {
      name = "arpa-home-authentik"
    }
  }

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2024.4.2"
    }
    doppler = {
      source = "DopplerHQ/doppler"
      version = "1.7.1"
    }
  }
}

module "secret_authentik" {
  # Remember to export OP_CONNECT_HOST and OP_CONNECT_TOKEN
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "k8s-home-ops"
  item   = "authentik"
}

# provider "authentik" {
#   url   = module.secret_authentik.fields["endpoint"]
#   token = module.secret_authentik.fields["tf_token"]
# }

provider "authentik" {
  url   = data.doppler_secrets.this.map.ENDPOINT
  token = data.doppler_secrets.this.map.TF_TOKEN
}
