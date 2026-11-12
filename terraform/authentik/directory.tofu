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

# LiteLLM role source: group attribute litellm_role=admin => admin in the
# LiteLLM UI (see expressions/openid-scope-litellm-role.py).
resource "authentik_group" "litellm-admin" {
  name         = "litellm-admin"
  is_superuser = false
  attributes   = jsonencode({ litellm_role = "admin" })
}
