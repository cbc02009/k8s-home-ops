terraform {

  cloud {
    organization = "kokoro-wtf"
    workspaces {
      name = "arpa-home-s3"
    }
  }

  required_providers {
    minio = {
      source = "aminueza/minio"
      version = "2.0.1"
    }
    doppler = {
      source = "DopplerHQ/doppler"
      version = "1.3.0"
    }
  }
}
