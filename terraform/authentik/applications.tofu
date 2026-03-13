module "proxy-frigate" {
  source                = "./proxy_application"
  name                  = "Frigate"
  description           = "DVR"
  icon_url              = "https://raw.githubusercontent.com/blakeblackshear/frigate/dev/web/images/favicon-32x32.png"
  group                 = "Home"
  slug                  = "frigate"
  domain                = var.public_domain
  authorization_flow    = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  invalidation_flow     = resource.authentik_flow.provider-invalidation.uuid
  auth_groups           = [authentik_group.home.id]
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

module "oauth2-karakeep" {
  source             = "./oauth2_application"
  name               = "Karakeep"
  icon_url           = "https://raw.githubusercontent.com/karakeep-app/karakeep/refs/heads/main/docs/static/img/favicon.ico"
  launch_url         = "https://karakeep.${var.public_domain}"
  description        = "bookmark managment"
  newtab             = true
  group              = "Selfhosted"
  auth_groups        = [authentik_group.users.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  invalidation_flow  = resource.authentik_flow.provider-invalidation.uuid
  client_id          = module.secret_karakeep.fields["oidc_id"]
  client_secret      = module.secret_karakeep.fields["oidc_secret"]
  redirect_uris      = ["https://karakeep.${var.public_domain}/api/auth/callback/custom"]
}

module "oauth2-immich" {
  source             = "./oauth2_application"
  name               = "Immich"
  icon_url           = "https://github.com/immich-app/immich/raw/main/docs/static/img/favicon.png"
  launch_url         = "https://photos.${var.public_domain}"
  description        = "Photo managment"
  newtab             = true
  group              = "SelfHosted"
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
  redirect_uris      = ["https://grafana.${var.public_domain}/login/generic_oauth"]
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

module "oauth2-Booklore" {
  source             = "./oauth2_application"
  name               = "Booklore"
  icon_url           = "https://raw.githubusercontent.com/booklore-app/booklore/refs/heads/develop/assets/logo.svg"
  launch_url         = "https://booklore.${var.public_domain}"
  description        = "Books"
  newtab             = true
  group              = "SelfHosted"
  auth_groups        = [authentik_group.users.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  invalidation_flow  = resource.authentik_flow.provider-invalidation.uuid
  client_id          = module.secret_booklore.fields["oidc_id"]
  # client_secret      = module.secret_booklore.fields["oidc_secret"]
  client_type        = "public"
  redirect_uris      = ["https://booklore.${var.public_domain}/oauth2-callback"]
  regex_uris         = ["https://booklore.${var.public_domain}/*"]
}

module "oauth2-paperless" {
  source             = "./oauth2_application"
  name               = "Paperless"
  icon_url           = "https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/dev/resources/logo/web/svg/Color%20logo%20-%20no%20background.svg"
  launch_url         = "https://documents.${var.public_domain}"
  description        = "Documents"
  newtab             = true
  group              = "SelfHosted"
  auth_groups        = [authentik_group.users.id]
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  invalidation_flow  = resource.authentik_flow.provider-invalidation.uuid
  client_id          = module.secret_paperless.fields["oidc_id"]
  client_secret      = module.secret_paperless.fields["oidc_secret"]
  redirect_uris      = ["https://documents.${var.public_domain}/accounts/oidc/authentik/login/callback/"]
}

module "oauth2-opencloud" {
  source             = "./oauth2_application"
  name               = "OpenCloud"
  icon_url           = "https://raw.githubusercontent.com/opencloud-eu/docs/refs/heads/main/static/img/oc-favicon.svg"
  launch_url         = "https://opencloud.${var.public_domain}"
  description        = "OpenCloud"
  newtab             = true
  group              = "SelfHosted"
  auth_groups        = [authentik_group.users.id]
  client_type        = "public"
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  invalidation_flow  = resource.authentik_flow.provider-invalidation.uuid
  client_id          = "web"
  # additional_property_mappings = formatlist(authentik_scope_mapping.openid-nextcloud.id)
  redirect_uris = [
    "https://opencloud.${var.public_domain}",
    "https://opencloud.${var.public_domain}/oidc-callback.html",
    "https://opencloud.${var.public_domain}/oidc-silent-redirect.html"
  ]
}

# module "oauth2-pgadmin" {
#   source = "./oauth2_application"
#   name = "PGadmin"
#   icon_url = "https://codeberg.org/forgejo/forgejo/raw/branch/forgejo/public/assets/img/forgejo.svg"
#   launch_url = "https://git.${var.public_domain}"
#   description = "Database Access"
#   newtab = true
#   group = "Infrastructure"
#   auth_groups = [authentik_group.admins.id]
#   authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
#   client_id          = module.secret_pgadmin.fields["oidc_id"]
#   client_secret      = module.secret_pgadmin.fields["oidc_secret"]
#   redirect_uris = ["https://git.${var.public_domain}/accounts/oidc/authentik/login/callback/"]
# }
