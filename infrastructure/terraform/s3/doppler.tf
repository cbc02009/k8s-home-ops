# Configure the Doppler provider with the token
provider "doppler" {
}

# Define our data source to fetch secrets
data "doppler_secrets" "this" {
  project="tf-s3"
  config="prd"
}
