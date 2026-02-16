module "s3_cloudnative-pg" {
  source      = "./modules/garage"
  vault       = "k8s-home-ops"
  bucket_name = "postgres"
  # The OP provider converts the fields with toLower!
  access_key = "garage_access_key"
  secret_key = "garage_secret_key"
}
