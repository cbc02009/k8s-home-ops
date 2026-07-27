variable "public_domain" {
  type    = string
  default = "ctec.run"
}

variable "private_domain" {
  type    = string
  default = "ctec.internal"
}

variable "enrollment_verify_email_subject" {
  type    = string
  default = "Confirm your email address"
}

variable "enrollment_verify_email_token_expiry" {
  type    = string
  default = "hours=24"
}
