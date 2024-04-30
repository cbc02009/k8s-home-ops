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
      version = "2024.4.0"
    }
    doppler = {
      source = "DopplerHQ/doppler"
      version = "1.7.0"
    }
  }
}


provider "authentik" {
  url   = data.doppler_secrets.this.map.ENDPOINT
  token = data.doppler_secrets.this.map.TF_TOKEN
}
