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
      version = "2.2.0"
    }
    doppler = {
      source = "DopplerHQ/doppler"
      version = "1.7.1"
    }
  }
}
