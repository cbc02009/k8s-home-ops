module "s3_dragonfly" {
  source      = "./modules/garage"
  vault       = "k8s-home-ops"
  bucket_name = "dragonfly"
  # The OP provider converts the fields with toLower!
  access_key = "access_key"
  secret_key = "secret_key"
}
