module "s3_forgejo" {
  source      = "./modules/minio"
  vault       = "k8s-home-ops"
  bucket_name = "forgejo"
  user_secret_item = "secret_key"
}
