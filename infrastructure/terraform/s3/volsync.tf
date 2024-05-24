module "s3_volsync" {
  source      = "./modules/minio"
  vault       = "k8s-home-ops"
  bucket_name = "volsync"
  user_secret_item = "secret_key"
}
