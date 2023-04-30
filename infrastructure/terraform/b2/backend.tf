terraform {
  cloud {
    organization = "kokoro-wtf"
    workspaces {
      name = "b2-provisioner"
    }
  }
}
