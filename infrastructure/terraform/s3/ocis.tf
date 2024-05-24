module "s3_ocis" {
  source      = "./modules/minio"
  vault       = "k8s-home-ops"
  bucket_name = "ocis"
  user_secret_item = "secret_key"
}
