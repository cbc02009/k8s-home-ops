data "authentik_certificate_key_pair" "generated" {
  name = "authentik Self-signed Certificate"
}

resource "authentik_brand" "home" {
  domain         = var.public_domain
  default        = false
  branding_title = "Authentik"

  flow_authentication = authentik_flow.authentication.uuid
  flow_invalidation   = authentik_flow.invalidation.uuid
  flow_user_settings  = authentik_flow.user-settings.uuid
}

resource "authentik_service_connection_kubernetes" "local" {
  name  = "local"
  local = true
}

resource "authentik_outpost" "proxyoutpost" {
  name               = "proxy-outpost"
  type               = "proxy"
  service_connection = authentik_service_connection_kubernetes.local.id
  protocol_providers = [
    module.proxy-frigate.id,
    module.proxy-calibre-web.id,
    # module.proxy-mealieproxy.id
  ]
  config = jsonencode({
    authentik_host         = "https://auth.${var.public_domain}",
    log_level              = "warning",
    object_naming_template = "ak-outpost-%(name)s",
    kubernetes_replicas    = 1,
    kubernetes_namespace   = "authentik",
    kubernetes_httproute_parent_refs = [{
      group       = "gateway.networking.k8s.io"
      kind        = "Gateway"
      name        = "envoy-internal"
      namespace   = "network"
      sectionName = "https"
    }]
    kubernetes_httproute_annotations = {
      "gatus.home-operations.com/enabled" = "false"
    }
    kubernetes_service_type        = "ClusterIP",
    kubernetes_disabled_components = ["ingress"],
  })
}

resource "authentik_system_settings" "settings" {
  avatars                   = "attributes.avatar, initials"
  default_user_change_email = true
  event_retention           = "days=14"
}
