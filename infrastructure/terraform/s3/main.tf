terraform {
  required_providers {
    minio = {
      source = "aminueza/minio"
      version = "1.16.0"
    }
    doppler = {
      source = "DopplerHQ/doppler"
      version = "1.2.2"
    }
  }
}
