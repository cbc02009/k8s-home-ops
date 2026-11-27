# RouterOS switches fleet — OpenTofu
# ebogdum/routeros is NOT on registry.opentofu.org: explicit host required.
terraform {
  required_version = ">= 1.8.0"
  required_providers {
    routeros = {
      source  = "registry.terraform.io/ebogdum/routeros"
      version = "~> 4.0"
    }
  }
}
