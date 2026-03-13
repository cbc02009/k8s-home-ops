resource "authentik_group" "users" {
  name = "users"
  attributes = jsonencode({
    storageQuota = "10GB"
  })
}

resource "authentik_group" "home" {
  name         = "home"
  is_superuser = false
}

resource "authentik_group" "infrastructure" {
  name         = "infrastructure"
  is_superuser = false
}
