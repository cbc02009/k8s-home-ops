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
      version = "2023.8.0"
    }
    doppler = {
      source = "DopplerHQ/doppler"
      version = "1.3.0"
    }
  }
}


provider "authentik" {
  url   = data.doppler_secrets.this.map.ENDPOINT
  token = data.doppler_secrets.this.map.TF_TOKEN
}
