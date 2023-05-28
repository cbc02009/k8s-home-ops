locals {
  networks = yamldecode(chomp(data.http.cbc02009_common_networks.response_body))
}
