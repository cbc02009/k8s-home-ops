provider "minio" {
  alias  = "nas"
  minio_server   = "minio.ctec.run:9000"
  minio_user     = module.onepassword_item_minio.fields.username
  minio_password = module.onepassword_item_minio.fields.password
}
