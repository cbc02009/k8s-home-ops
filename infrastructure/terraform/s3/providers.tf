provider "minio" {
  alias  = "nas"
  minio_server   = "minio.ctec.run:9000"
  minio_user     = data.doppler_secrets.this.map.MINIO_USER
  minio_password = data.doppler_secrets.this.map.MINIO_PASSWORD
}
