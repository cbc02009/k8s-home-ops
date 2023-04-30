provider "b2" {
  application_key    = module.onepassword_item_b2.fields.username
  application_key_id = module.onepassword_item_b2.fields.password
}
