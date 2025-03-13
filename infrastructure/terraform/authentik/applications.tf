# module "proxy-prowlarr" {
#   source             = "./proxy_application"
#   name               = "Prowlarr"
#   description        = "Torrent indexer"
#   icon_url           = "https://raw.githubusercontent.com/Prowlarr/Prowlarr/develop/Logo/128.png"
#   group              = "Media"
#   slug               = "prowlarr"
#   domain             = module.secret_authentik.fields["domain"]
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
#   domain             = module.secret_authentik.fields["domain"]
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
#   domain             = module.secret_authentik.fields["domain"]
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
#   domain             = module.secret_authentik.fields["domain"]
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
#   domain             = module.secret_authentik.fields["domain"]
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
#   domain             = module.secret_authentik.fields["domain"]
#   authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
#   auth_groups        = [authentik_group.media.id]
# }

module "proxy-whoogle" {
  source             = "./proxy_application"
  name               = "Whoogle"
  description        = "Search"
  icon_url           = "https://raw.githubusercontent.com/benbusby/whoogle-search/main/app/static/img/favicon/apple-icon-120x120.png"
  slug               = "search"
  domain             = module.secret_authentik.fields["domain"]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  auth_groups        = [authentik_group.search.id]
  access_token_validity = "weeks=20"
}

module "proxy-frigate" {
  source             = "./proxy_application"
  name               = "Frigate"
  description        = "DVR"
  icon_url           = "https://raw.githubusercontent.com/blakeblackshear/frigate/dev/web/images/favicon-32x32.png"
  slug               = "frigate"
  domain             = module.secret_authentik.fields["domain"]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  group              = "Home Automation"
  auth_groups        = [authentik_group.home.id]
  access_token_validity = "weeks=20"
}

module "proxy-calibre-web" {
  source             = "./proxy_application"
  name               = "Calibre Web"
  description        = "Books"
  slug               = "cwa"
  domain             = module.secret_authentik.fields["domain"]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  group              = "Media"
  auth_groups        = [authentik_group.media.id]
  access_token_validity = "weeks=20"
}

module "proxy-tandoor" {
  source             = "./proxy_application"
  name               = "Recipes"
  description        = "Recipes"
  icon_url           = "https://raw.githubusercontent.com/TandoorRecipes/recipes/develop/docs/logo_color.svg"
  slug               = "recipes"
  domain             = module.secret_authentik.fields["domain"]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  auth_groups        = [authentik_group.media.id]
  access_token_validity = "weeks=20"
}

module "oauth2-immich" {
  source             = "./oauth2_application"
  name               = "Immich"
  icon_url           = "https://github.com/immich-app/immich/raw/main/docs/static/img/favicon.png"
  launch_url         = "https://photos.${module.secret_authentik.fields["domain"]}"
  description        = "Photo managment"
  newtab             = true
  group              = "Media"
  auth_groups        = [authentik_group.media.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  client_id          = module.secret_immich.fields["oidc_id"]
  client_secret      = module.secret_immich.fields["oidc_secret"]
  redirect_uris = [
    "https://photos.${module.secret_authentik.fields["domain"]}/auth/login",
    "app.immich:/"
  ]
}

module "oauth2-grafana" {
  source             = "./oauth2_application"
  name               = "Grafana"
  icon_url           = "https://raw.githubusercontent.com/grafana/grafana/main/public/img/icons/mono/grafana.svg"
  launch_url         = "https://grafana.${module.secret_authentik.fields["domain"]}"
  description        = "Infrastructure graphs"
  newtab             = true
  group              = "Infrastructure"
  auth_groups        = [authentik_group.infrastructure.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  client_id          = module.secret_grafana.fields["oidc_id"]
  client_secret      = module.secret_grafana.fields["oidc_secret"]
  redirect_uris      = ["https://grafana.${module.secret_authentik.fields["domain"]}/login/generic_oauth"]
}

module "oauth2-tandoor" {
  source                     = "./oauth2_application"
  name                       = "tandoor"
  icon_url                   = "https://raw.githubusercontent.com/TandoorRecipes/recipes/develop/docs/logo_color.svg"
  launch_url                 = "https://recipes.${module.secret_authentik.fields["domain"]}"
  description                = "Recipes"
  newtab                     = true
  group                      = "Media"
  auth_groups                = [authentik_group.media.id]
  authorization_flow         = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  client_id                  = module.secret_tandoor.fields["oidc_id"]
  client_secret              = module.secret_tandoor.fields["oidc_secret"]
  include_claims_in_id_token = false
  sub_mode                   = "user_username"
  redirect_uris              = ["https://recipes.${module.secret_authentik.fields["domain"]}/accounts/oidc/authentik/login/callback/"]
}

module "oauth2-paperless" {
  source = "./oauth2_application"
  name = "Paperless"
  icon_url = "https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/dev/resources/logo/web/svg/Color%20logo%20-%20no%20background.svg"
  launch_url = "https://paperless.${module.secret_authentik.fields["domain"]}"
  description = "Documents"
  newtab = true
  group = "Groupware"
  auth_groups = [authentik_group.infrastructure.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  client_id          = module.secret_paperless.fields["oidc_id"]
  client_secret      = module.secret_paperless.fields["oidc_secret"]
  redirect_uris = ["https://paperless.${module.secret_authentik.fields["domain"]}/accounts/oidc/authentik/login/callback/"]
}

# module "oauth2-pgadmin" {
#   source = "./oauth2_application"
#   name = "PGadmin"
#   icon_url = "https://codeberg.org/forgejo/forgejo/raw/branch/forgejo/public/assets/img/forgejo.svg"
#   launch_url = "https://git.${module.secret_authentik.fields["domain"]}"
#   description = "Database Access"
#   newtab = true
#   group = "Infrastructure"
#   auth_groups = [authentik_group.infrastructure.id]
#   authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
#   client_id          = module.secret_pgadmin.fields["oidc_id"]
#   client_secret      = module.secret_pgadmin.fields["oidc_secret"]
#   redirect_uris = ["https://git.${module.secret_authentik.fields["domain"]}/accounts/oidc/authentik/login/callback/"]
# }
