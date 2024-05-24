module "s3_tandoor" {
  source      = "./modules/minio"
  vault       = "k8s-home-ops"
  bucket_name = "tandoor"
  user_secret_item = "s3_secret_key"
}
