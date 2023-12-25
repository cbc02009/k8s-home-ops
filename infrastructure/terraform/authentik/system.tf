data "authentik_certificate_key_pair" "generated" {
  name = "authentik Self-signed Certificate"
}

# resource "authentik_tenant" "home" {
#   domain           = data.doppler_secrets.this.map.DOMAIN
#   default          = false
#   branding_title   = "Home"

#   flow_authentication = authentik_flow.authentication.uuid
#   flow_invalidation   = authentik_flow.invalidation.uuid
#   flow_user_settings  = authentik_flow.user-settings.uuid
#   event_retention     = "days=365"
# }

resource "authentik_service_connection_kubernetes" "local" {
  name  = "local"
  local = true
}

resource "authentik_outpost" "proxyoutpost" {
  name               = "proxy-outpost"
  type               = "proxy"
  service_connection = authentik_service_connection_kubernetes.local.id
  protocol_providers = [
    module.proxy-prowlarr.id,
    module.proxy-radarr.id,
    module.proxy-sonarr.id,
    module.proxy-lidarr.id,
    module.proxy-readarr.id,
    module.proxy-animarr.id,
    module.proxy-whoogle.id,
    module.proxy-frigate.id,
  ]
  config = jsonencode({
    authentik_host          = "https://auth.${data.doppler_secrets.this.map.DOMAIN}",
    authentik_host_insecure = false,
    authentik_host_browser  = "",
    log_level               = "info",
    object_naming_template  = "ak-outpost-%(name)s",
    docker_network          = null,
    docker_map_ports        = true,
    docker_labels           = null,
    container_image         = null,
    kubernetes_replicas     = 1,
    kubernetes_namespace    = "security",
    kubernetes_ingress_annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt-production"
    },
    kubernetes_ingress_class_name = "external",
    kubernetes_ingress_secret_name = "proxy-outpost-tls",
    kubernetes_service_type        = "ClusterIP",
    kubernetes_disabled_components = [],
    kubernetes_image_pull_secrets  = []
  })
}
