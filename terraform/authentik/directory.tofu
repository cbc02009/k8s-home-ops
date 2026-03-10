data "authentik_group" "admins" {
  name = "authentik Admins"
}


resource "authentik_group" "users" {
  name = "users"
  attributes = jsonencode({
    storageQuota = "10GB"
  })
}

resource "authentik_group" "home" {
  name         = "Home"
  is_superuser = false
}
