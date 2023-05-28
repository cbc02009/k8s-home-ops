locals {
  ap_office_name           = "AP - Office"
  ap_hallway_name          = "AP - Hallway"
  ap_basement_name         = "AP - Basement"
}

resource "unifi_device" "ap_office" {
  mac  = "60:22:32:41:5b:74"
  name = local.ap_office_name
  site = unifi_site.default.name
}

resource "unifi_device" "ap_hallway" {
  mac  = "60:22:32:40:d6:8c"
  name = local.ap_hallway_name
  site = unifi_site.default.name
}

resource "unifi_device" "ap_basement" {
  mac  = "ac:8b:a9:24:ae:95"
  name = local.ap_basement_name
  site = unifi_site.default.name
}
