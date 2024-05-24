module "s3_loki" {
  source      = "./modules/minio"
  vault       = "k8s-home-ops"
  bucket_name = "loki"
  user_secret_item = "secret_key"
}
