# module "proxy-prowlarr" {
#   source             = "./proxy_application"
#   name               = "Prowlarr"
#   description        = "Torrent indexer"
#   icon_url           = "https://raw.githubusercontent.com/Prowlarr/Prowlarr/develop/Logo/128.png"
#   group              = "Media"
#   slug               = "prowlarr"
#   domain             = var.public_domain
#   authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
#   auth_groups        = [authentik_group.media.id]
# }

# module "proxy-radarr" {
#   source             = "./proxy_application"
#   name               = "Radarr"
#   description        = "Movies"
#   icon_url           = "https://github.com/Radarr/Radarr/raw/develop/Logo/128.png"
#   group              = "Media"
#   slug               = "radarr"
#   domain             = var.public_domain
#   authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
#   auth_groups        = [authentik_group.media.id]
# }

# module "proxy-sonarr" {
#   source             = "./proxy_application"
#   name               = "Sonarr"
#   description        = "TV"
#   icon_url           = "https://github.com/Sonarr/Sonarr/raw/develop/Logo/128.png"
#   group              = "Media"
#   slug               = "sonarr"
#   domain             = var.public_domain
#   authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
#   auth_groups        = [authentik_group.media.id]
# }

# module "proxy-animarr" {
#   source             = "./proxy_application"
#   name               = "Animarr"
#   description        = "TV"
#   icon_url           = "https://github.com/Sonarr/Sonarr/raw/develop/Logo/128.png"
#   group              = "Media"
#   slug               = "animarr"
#   domain             = var.public_domain
#   authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
#   auth_groups        = [authentik_group.media.id]
# }

# module "proxy-lidarr" {
#   source             = "./proxy_application"
#   name               = "Lidarr"
#   description        = "Music"
#   icon_url           = "https://github.com/Lidarr/Lidarr/raw/develop/Logo/128.png"
#   group              = "Media"
#   slug               = "lidarr"
#   domain             = var.public_domain
#   authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
#   auth_groups        = [authentik_group.media.id]
# }

# module "proxy-readarr" {
#   source             = "./proxy_application"
#   name               = "Readarr"
#   description        = "Books"
#   icon_url           = "https://github.com/Readarr/Readarr/raw/develop/Logo/128.png"
#   group              = "Media"
#   slug               = "readarr"
#   domain             = var.public_domain
#   authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
#   auth_groups        = [authentik_group.media.id]
# }

module "proxy-frigate" {
  source             = "./proxy_application"
  name               = "Frigate"
  description        = "DVR"
  icon_url           = "https://raw.githubusercontent.com/blakeblackshear/frigate/dev/web/images/favicon-32x32.png"
  group              = "Home"
  slug               = "frigate"
  domain             = var.public_domain
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  invalidation_flow  = resource.authentik_flow.provider-invalidation.uuid
  auth_groups        = [authentik_group.home.id]
  access_token_validity = "weeks=20"
}

module "proxy-calibre-web" {
  source             = "./proxy_application"
  name               = "Calibre Web"
  description        = "Books"
  group              = "Selfhosted"
  slug               = "cwa"
  domain             = var.public_domain
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  invalidation_flow  = resource.authentik_flow.provider-invalidation.uuid
  auth_groups        = [authentik_group.users.id]
  access_token_validity = "weeks=20"
}

# module "proxy-mealieproxy" {
#   source             = "./proxy_application"
#   name               = "Mealie Proxy"
#   description        = "Recipes"
#   icon_url           = "https://raw.githubusercontent.com/mealie-recipes/mealie/refs/heads/mealie-next/frontend/static/icons/icon-x64.png"
#   slug               = "mealie"
#   domain             = var.public_domain
#   authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
#   invalidation_flow  = resource.authentik_flow.provider-invalidation.uuid
#   auth_groups        = [authentik_group.users.id]
#   access_token_validity = "weeks=20"
# }

module "oauth2-immich" {
  source             = "./oauth2_application"
  name               = "Immich"
  icon_url           = "https://github.com/immich-app/immich/raw/main/docs/static/img/favicon.png"
  launch_url         = "https://photos.${var.public_domain}"
  description        = "Photo managment"
  newtab             = true
  group              = "Selfhosted"
  auth_groups        = [authentik_group.home.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  invalidation_flow  = resource.authentik_flow.provider-invalidation.uuid
  client_id          = module.secret_immich.fields["oidc_id"]
  client_secret      = module.secret_immich.fields["oidc_secret"]
  redirect_uris = [
    "https://photos.${var.public_domain}/auth/login",
    "app.immich:///oauth-callback"
  ]
}

module "oauth2-grafana" {
  source             = "./oauth2_application"
  name               = "Grafana"
  icon_url           = "https://raw.githubusercontent.com/grafana/grafana/main/public/img/icons/mono/grafana.svg"
  launch_url         = "https://grafana.${var.public_domain}"
  description        = "Infrastructure graphs"
  newtab             = true
  group              = "Infrastructure"
  auth_groups        = [authentik_group.infrastructure.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  invalidation_flow  = resource.authentik_flow.provider-invalidation.uuid
  client_id          = module.secret_grafana.fields["oidc_id"]
  client_secret      = module.secret_grafana.fields["oidc_secret"]
  redirect_uris      = ["https://grafana.${var.private_domain}/login/generic_oauth"]
}

module "oauth2-Mealie" {
  source             = "./oauth2_application"
  name               = "Mealie"
  icon_url           = "https://raw.githubusercontent.com/mealie-recipes/mealie/refs/heads/mealie-next/frontend/static/icons/icon-x64.png"
  launch_url         = "https://mealie.${var.public_domain}"
  description        = "Recipes"
  newtab             = true
  group              = "SelfHosted"
  auth_groups        = [authentik_group.users.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  invalidation_flow  = resource.authentik_flow.provider-invalidation.uuid
  client_id          = module.secret_mealie.fields["oidc_id"]
  client_secret      = module.secret_mealie.fields["oidc_secret"]
  redirect_uris = [
    "https://mealie.${var.public_domain}/login",
    "https://mealie.${var.public_domain}/login?direct=1"
  ]
}

module "oauth2-paperless" {
  source = "./oauth2_application"
  name = "Paperless"
  icon_url           = "https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/dev/resources/logo/web/svg/Color%20logo%20-%20no%20background.svg"
  launch_url         = "https://documents.${var.private_domain}"
  description        = "Documents"
  newtab             = true
  group              = "Selfhosted"
  auth_groups        = [authentik_group.users.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  invalidation_flow  = resource.authentik_flow.provider-invalidation.uuid
  client_id          = module.secret_paperless.fields["oidc_id"]
  client_secret      = module.secret_paperless.fields["oidc_secret"]
  redirect_uris      = ["https://documents.${var.private_domain}/accounts/oidc/authentik/login/callback/"]
}

# module "oauth2-pgadmin" {
#   source = "./oauth2_application"
#   name = "PGadmin"
#   icon_url = "https://codeberg.org/forgejo/forgejo/raw/branch/forgejo/public/assets/img/forgejo.svg"
#   launch_url = "https://git.${var.public_domain}"
#   description = "Database Access"
#   newtab = true
#   group = "Infrastructure"
#   auth_groups = [authentik_group.infrastructure.id]
#   authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
#   client_id          = module.secret_pgadmin.fields["oidc_id"]
#   client_secret      = module.secret_pgadmin.fields["oidc_secret"]
#   redirect_uris = ["https://git.${var.public_domain}/accounts/oidc/authentik/login/callback/"]
# }
