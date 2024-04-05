# module "proxy-prowlarr" {
#   source             = "./proxy_application"
#   name               = "Prowlarr"
#   description        = "Torrent indexer"
#   icon_url           = "https://raw.githubusercontent.com/Prowlarr/Prowlarr/develop/Logo/128.png"
#   group              = "Media"
#   slug               = "prowlarr"
#   domain             = data.doppler_secrets.this.map.DOMAIN
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
#   domain             = data.doppler_secrets.this.map.DOMAIN
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
#   domain             = data.doppler_secrets.this.map.DOMAIN
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
#   domain             = data.doppler_secrets.this.map.DOMAIN
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
#   domain             = data.doppler_secrets.this.map.DOMAIN
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
#   domain             = data.doppler_secrets.this.map.DOMAIN
#   authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
#   auth_groups        = [authentik_group.media.id]
# }

module "proxy-whoogle" {
  source             = "./proxy_application"
  name               = "Whoogle"
  description        = "Search"
  icon_url           = "https://raw.githubusercontent.com/benbusby/whoogle-search/main/app/static/img/favicon/apple-icon-120x120.png"
  slug               = "search"
  domain             = data.doppler_secrets.this.map.DOMAIN
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  auth_groups        = [authentik_group.search.id]
  access_token_validity = 720
}

module "proxy-frigate" {
  source             = "./proxy_application"
  name               = "Frigate"
  description        = "DVR"
  icon_url           = "https://raw.githubusercontent.com/blakeblackshear/frigate/dev/web/images/favicon-32x32.png"
  slug               = "frigate"
  domain             = data.doppler_secrets.this.map.DOMAIN
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  group              = "Home Automation"
  auth_groups        = [authentik_group.home.id]
  access_token_validity = 720
}

module "oauth2-immich" {
  source             = "./oauth2_application"
  name               = "Immich"
  icon_url           = "https://github.com/immich-app/immich/raw/main/docs/static/img/favicon.png"
  launch_url         = "https://photos.${data.doppler_secrets.this.map.DOMAIN}"
  description        = "Photo managment"
  newtab             = true
  group              = "Media"
  auth_groups        = [authentik_group.media.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  client_id          = data.doppler_secrets.this.map.IMMICH_OIDC_ID
  client_secret      = data.doppler_secrets.this.map.IMMICH_OIDC_SECRET
  redirect_uris = [
    "https://photos.${data.doppler_secrets.this.map.DOMAIN}/auth/login",
    "app.immich:/"
  ]
}

module "oauth2-grafana" {
  source             = "./oauth2_application"
  name               = "Grafana"
  icon_url           = "https://raw.githubusercontent.com/grafana/grafana/main/public/img/icons/mono/grafana.svg"
  launch_url         = "https://grafana.${data.doppler_secrets.this.map.DOMAIN}"
  description        = "Infrastructure graphs"
  newtab             = true
  group              = "Infrastructure"
  auth_groups        = [authentik_group.infrastructure.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  client_id          = data.doppler_secrets.this.map.GRAFANA_OIDC_ID
  client_secret      = data.doppler_secrets.this.map.GRAFANA_OIDC_SECRET
  redirect_uris      = ["https://grafana.${data.doppler_secrets.this.map.DOMAIN}/login/generic_oauth"]
}

module "oauth2-tandoor" {
  source                     = "./oauth2_application"
  name                       = "Recipes"
  icon_url                   = "https://raw.githubusercontent.com/TandoorRecipes/recipes/develop/docs/logo_color.svg"
  launch_url                 = "https://recipes.${data.doppler_secrets.this.map.DOMAIN}"
  description                = "Recipes"
  newtab                     = true
  group                      = "Media"
  auth_groups                = [authentik_group.media.id]
  authorization_flow         = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  client_id                  = data.doppler_secrets.this.map.TANDOOR_OIDC_ID
  client_secret              = data.doppler_secrets.this.map.TANDOOR_OIDC_SECRET
  include_claims_in_id_token = false
  sub_mode                   = "user_username"
  redirect_uris              = ["https://recipes.${data.doppler_secrets.this.map.DOMAIN}/accounts/oidc/authentik/login/callback/"]
}

module "oauth2-paperless" {
  source = "./oauth2_application"
  name = "Paperless"
  icon_url = "https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/dev/resources/logo/web/svg/Color%20logo%20-%20no%20background.svg"
  launch_url = "https://paperless.${data.doppler_secrets.this.map.DOMAIN}"
  description = "Documents"
  newtab = true
  group = "Groupware"
  auth_groups = [authentik_group.infrastructure.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  client_id          = data.doppler_secrets.this.map.PAPERLESS_OIDC_ID
  client_secret      = data.doppler_secrets.this.map.PAPERLESS_OIDC_SECRET
  redirect_uris = ["https://paperless.${data.doppler_secrets.this.map.DOMAIN}/accounts/oidc/authentik/login/callback/"]
}
