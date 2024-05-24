module "s3_thanos" {
  source      = "./modules/minio"
  vault       = "k8s-home-ops"
  bucket_name = "thanos"
  user_secret_item = "secret_key"
}
