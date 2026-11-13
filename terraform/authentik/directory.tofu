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

# LiteLLM role source: group attribute litellm_role=proxy_admin => admin in the
# LiteLLM UI (see expressions/openid-scope-litellm-role.py). The value must
# match LiteLLM's LitellmUserRoles enum — the legacy "admin"/"user" roles were
# removed upstream, so "admin" was silently ignored and users stayed non-admin.
resource "authentik_group" "litellm-admin" {
  name         = "litellm-admin"
  is_superuser = false
  attributes   = jsonencode({ litellm_role = "proxy_admin" })
}
