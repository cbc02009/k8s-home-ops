output "fields" {
  description = "A map of all fields that are available in the 1Password Item"
  sensitive   = true
  # NOTE: The 1Password provider only exposes fields that live inside sections.
  # Root-level custom fields are not returned by the onepassword_item data source.
  # See: https://github.com/1Password/terraform-provider-onepassword/issues/337
  # Always place custom fields (e.g. oidc_id, oidc_secret) inside a section.
  value = merge(
    {
      username = data.onepassword_item.item.username
      password = data.onepassword_item.item.password
    },
    merge([
      for section in data.onepassword_item.item.section : merge([
        for field in section.field :
        {
          "${field.label}" = field.type == "CONCEALED" ? sensitive(field.value) : field.value
        }
      ]...)
    ]...)
  )
}
