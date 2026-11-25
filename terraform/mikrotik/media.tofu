# media-switch — generated from live inventory via MikroMCP (2026-11-25).
# Import each existing object before the first apply, e.g.:
#   tofu import 'routeros_<type>.<res>' 'media/<.id>'
# Applies are gated on a human-reviewed plan.

resource "routeros_interface_list" "media_WAN" {
  router = "media"
  name   = "WAN"
}

resource "routeros_interface_list" "media_LAN" {
  router = "media"
  name   = "LAN"
}

resource "routeros_interface_bridge" "media_bridge" {
  router   = "media"
  name     = "bridge"
  arp      = "enabled"
  mtu      = "auto"
  priority = 32768
}

resource "routeros_interface_bridge_vlan" "media_Trusted" {
  router   = "media"
  bridge   = "bridge"
  comment  = "Trusted"
  vlan_ids = "10"
  tagged   = "ether1,sfp-sfpplus1"
  untagged = "sfp-sfpplus2,sfp-sfpplus3"
}

resource "routeros_interface_bridge_vlan" "media_Servers" {
  router   = "media"
  bridge   = "bridge"
  comment  = "Servers"
  vlan_ids = "20"
  tagged   = "sfp-sfpplus1"
  untagged = ""
}

resource "routeros_interface_bridge_vlan" "media_Guest" {
  router   = "media"
  bridge   = "bridge"
  comment  = "Guest"
  vlan_ids = "30"
  tagged   = "ether1,sfp-sfpplus1,sfp-sfpplus3"
  untagged = ""
}

resource "routeros_interface_bridge_vlan" "media_IoT" {
  router   = "media"
  bridge   = "bridge"
  comment  = "IoT"
  vlan_ids = "40"
  tagged   = "ether1,sfp-sfpplus1,sfp-sfpplus3"
  untagged = ""
}

resource "routeros_interface_bridge_vlan" "media_Video" {
  router   = "media"
  bridge   = "bridge"
  comment  = "Video"
  vlan_ids = "50"
  tagged   = "ether1,sfp-sfpplus1,sfp-sfpplus3"
  untagged = ""
}

resource "routeros_interface_bridge_port" "media_ether1" {
  router    = "media"
  bridge    = "bridge"
  interface = "ether1"
  pvid      = 1
  comment   = "defconf"
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "media_sfp_sfpplus1" {
  router    = "media"
  bridge    = "bridge"
  interface = "sfp-sfpplus1"
  pvid      = 1
  comment   = "defconf"
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "media_sfp_sfpplus2" {
  router    = "media"
  bridge    = "bridge"
  interface = "sfp-sfpplus2"
  pvid      = 10
  comment   = "defconf"
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "media_sfp_sfpplus3" {
  router    = "media"
  bridge    = "bridge"
  interface = "sfp-sfpplus3"
  pvid      = 1
  comment   = "defconf"
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "media_sfp_sfpplus4" {
  router    = "media"
  bridge    = "bridge"
  interface = "sfp-sfpplus4"
  pvid      = 1
  comment   = "defconf"
  edge      = "auto"
  hw        = true
}

resource "routeros_ip_address" "media_sfp_sfpplus1" {
  router    = "media"
  address   = "10.0.0.6/24"
  interface = "sfp-sfpplus1"
}

resource "routeros_interface_list_member" "media_WAN_ether1" {
  router    = "media"
  list      = "WAN"
  interface = "ether1"
}

resource "routeros_interface_list_member" "media_LAN_sfp_sfpplus1" {
  router    = "media"
  list      = "LAN"
  interface = "sfp-sfpplus1"
}

resource "routeros_interface_list_member" "media_LAN_sfp_sfpplus2" {
  router    = "media"
  list      = "LAN"
  interface = "sfp-sfpplus2"
}

resource "routeros_interface_list_member" "media_LAN_sfp_sfpplus3" {
  router    = "media"
  list      = "LAN"
  interface = "sfp-sfpplus3"
}

resource "routeros_interface_list_member" "media_LAN_sfp_sfpplus4" {
  router    = "media"
  list      = "LAN"
  interface = "sfp-sfpplus4"
}
