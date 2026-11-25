# Credentials come from the environment (TF_VAR_*); never in git.
provider "routeros" {
  insecure = true # switches serve self-signed TLS on www-ssl

  routers = {
    backbone = {
      host     = "https://10.0.0.2"
      username = var.backbone_user
      password = var.backbone_pass
    }
    office = {
      host     = "http://10.0.0.4"
      username = var.office_user
      password = var.office_pass
    }
    media = {
      host     = "http://10.0.0.6"
      username = var.media_user
      password = var.media_pass
    }
    cluster = {
      host     = "http://10.0.0.7"
      username = var.cluster_user
      password = var.cluster_pass
    }
  }
}

variable "backbone_user" { type = string }
variable "backbone_pass" {
  type      = string
  sensitive = true
}
variable "office_user" { type = string }
variable "office_pass" {
  type      = string
  sensitive = true
}
variable "media_user" { type = string }
variable "media_pass" {
  type      = string
  sensitive = true
}
variable "cluster_user" { type = string }
variable "cluster_pass" {
  type      = string
  sensitive = true
}
