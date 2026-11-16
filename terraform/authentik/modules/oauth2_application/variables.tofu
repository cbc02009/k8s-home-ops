variable "name" {
  type = string
}

variable "icon_url" {
  type    = string
  default = ""
}

variable "launch_url" {
  type    = string
  default = ""
}

variable "description" {
  type    = string
  default = ""
}

variable "meta_hide" {
  type    = bool
  default = false
}

variable "newtab" {
  type    = bool
  default = true
}

variable "group" {
  type    = string
  default = ""
}

variable "auth_groups" {
  type = list(string)
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type    = string
  default = null
}

variable "slug" {
  type    = string
  default = null
}

variable "authorization_flow" {
  type = string
}

variable "invalidation_flow" {
  type = string
}

variable "client_type" {
  type    = string
  default = "confidential"
}

variable "include_claims_in_id_token" {
  type    = bool
  default = true
}

variable "issuer_mode" {
  type    = string
  default = "per_provider"
}

variable "sub_mode" {
  type    = string
  default = "hashed_user_id"
}

variable "access_code_validity" {
  type    = string
  default = "minutes=1"
}

variable "access_token_validity" {
  type    = string
  default = "minutes=10"
}

variable "refresh_token_threshold" {
  type    = string
  default = "days=1"
}

# Token lifetimes match Authentik defaults except refresh_token_threshold:
#   access_token_validity    minutes=10  (Authentik default)
#   refresh_token_validity   days=30     (Authentik default, left unset)
#   refresh_token_threshold  days=1      (override: re-mint only when <1 day left)
# Refresh tokens are enabled by grant_types plus the offline_access scope.

variable "grant_types" {
  type    = list(string)
  default = ["authorization_code", "refresh_token"]
}

variable "additional_property_mappings" {
  type    = list(string)
  default = []
}

variable "redirect_uris" {
  type = list(any)
}

variable "logout_method" {
  type    = string
  default = "backchannel"
}

variable "logout_uri" {
  type    = string
  default = ""
}

locals {
  client_secret = (
    var.client_type == "confidential"
    ? var.client_secret != null ? var.client_secret : random_password.client_secret.result
    : null
  )

  allowed_redirect_uris = [
    for uri in var.redirect_uris : (
      can(uri.url) ? {
        matching_mode     = lookup(uri, "matching_mode", "strict")
        redirect_uri_type = lookup(uri, "redirect_uri_type", "authorization")
        url               = uri.url
        } : {
        matching_mode     = "strict"
        redirect_uri_type = "authorization"
        url               = trim(uri, " ")
      }
    )
  ]
}
