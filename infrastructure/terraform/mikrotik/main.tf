terraform {
  cloud {
    organization = "kokoro-wtf"
    workspaces {
      name = "arpa-home-mikrotik"
    }
  }

  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.22.0"
    }
    doppler = {
      source = "DopplerHQ/doppler"
      version = "1.3.0"
    }
  }
}
