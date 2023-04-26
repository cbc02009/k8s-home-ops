provider "minio" {
  alias  = "nas"
  minio_server   = "minio.kokoro.wtf"
  minio_user     = module.onepassword_item_minio.fields.username
  minio_password = module.onepassword_item_minio.fields.password
}
