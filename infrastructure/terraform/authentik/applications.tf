module "proxy-prowlarr" {
  source             = "./proxy_application"
  name               = "Prowlarr"
  description        = "Torrent indexer"
  icon_url           = "https://raw.githubusercontent.com/Prowlarr/Prowlarr/develop/Logo/128.png"
  group              = "Media"
  slug               = "prowlarr"
  domain             = data.doppler_secrets.this.map.DOMAIN
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  auth_groups        = [authentik_group.media.id]
}

module "proxy-radarr" {
  source             = "./proxy_application"
  name               = "Radarr"
  description        = "Movies"
  icon_url           = "https://github.com/Radarr/Radarr/raw/develop/Logo/128.png"
  group              = "Media"
  slug               = "radarr"
  domain             = data.doppler_secrets.this.map.DOMAIN
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  auth_groups        = [authentik_group.media.id]
}

module "proxy-sonarr" {
  source             = "./proxy_application"
  name               = "Sonarr"
  description        = "TV"
  icon_url           = "https://github.com/Sonarr/Sonarr/raw/develop/Logo/128.png"
  group              = "Media"
  slug               = "sonarr"
  domain             = data.doppler_secrets.this.map.DOMAIN
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  auth_groups        = [authentik_group.media.id]
}

module "proxy-animarr" {
  source             = "./proxy_application"
  name               = "Animarr"
  description        = "TV"
  icon_url           = "https://github.com/Sonarr/Sonarr/raw/develop/Logo/128.png"
  group              = "Media"
  slug               = "animarr"
  domain             = data.doppler_secrets.this.map.DOMAIN
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  auth_groups        = [authentik_group.media.id]
}

module "proxy-lidarr" {
  source             = "./proxy_application"
  name               = "Lidarr"
  description        = "Music"
  icon_url           = "https://github.com/Lidarr/Lidarr/raw/develop/Logo/128.png"
  group              = "Media"
  slug               = "lidarr"
  domain             = data.doppler_secrets.this.map.DOMAIN
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  auth_groups        = [authentik_group.media.id]
}

module "proxy-whoogle" {
  source             = "./proxy_application"
  name               = "Whoogle"
  description        = "Search"
  icon_url           = "https://raw.githubusercontent.com/benbusby/whoogle-search/main/app/static/img/favicon/apple-icon-120x120.png"
  slug               = "search"
  domain             = data.doppler_secrets.this.map.DOMAIN
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  auth_groups        = [authentik_group.search.id]
}

module "proxy-frigate" {
  source             = "./proxy_application"
  name               = "Frigate"
  description        = "DVR"
  icon_url           = "https://raw.githubusercontent.com/blakeblackshear/frigate/blob/dev/web/images/apple-touch-icon.png"
  slug               = "frigate"
  domain             = data.doppler_secrets.this.map.DOMAIN
  authorization_flow = resource.authentik_flow.provider-authorization-implicit-consent.uuid
  auth_groups        = [authentik_group.home.id]
}
