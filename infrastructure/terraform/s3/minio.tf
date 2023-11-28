locals {
  minio_buckets = [
    "loki",
    "thanos",
    "volsync",
  ]
}

module "minio_bucket" {
  for_each         = toset(local.minio_buckets)
  source           = "./modules/minio_bucket"
  bucket_name      = each.key
  is_public        = false
  owner_access_key = lookup(data.doppler_secrets.this.map, upper("${each.key}_ACCESS_KEY"))
  owner_secret_key = lookup(data.doppler_secrets.this.map, upper("${each.key}_SECRET_KEY"))
  providers = {
    minio = minio.nas
  }
}

output "minio_bucket_outputs" {
  value     = module.minio_bucket
  sensitive = true
}
