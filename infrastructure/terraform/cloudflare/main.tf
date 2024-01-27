terraform {
  cloud {
    organization = "kokoro-wtf"
    workspaces {
      name = "arpa-home-cloudflare"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.22.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.1"
    }
    doppler = {
      source = "DopplerHQ/doppler"
      version = "1.4.0"
    }
  }
}

# Obtain current home IP address
data "http" "ipv4_lookup_raw" {
  url = "http://ipv4.icanhazip.com"
}
