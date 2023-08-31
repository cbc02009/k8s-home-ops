terraform {

  cloud {
    organization = "kokoro-wtf"
    workspaces {
      name = "home-s3-provisioner"
    }
  }

  required_providers {
    minio = {
      source = "aminueza/minio"
      version = "1.17.2"
    }
    doppler = {
      source = "DopplerHQ/doppler"
      version = "1.2.4"
    }
  }
}
