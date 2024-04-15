provider "minio" {
  alias  = "nas"
  minio_server   = "s3.cnas.dev"
  minio_user     = data.doppler_secrets.this.map.MINIO_USER
  minio_password = data.doppler_secrets.this.map.MINIO_PASSWORD
  minio_ssl = true
}
