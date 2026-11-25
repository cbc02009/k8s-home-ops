# office-switch — generated from live inventory via MikroMCP (2026-11-25).
# Import each existing object before the first apply, e.g.:
#   tofu import 'routeros_<type>.<res>' 'office/<.id>'
# Applies are gated on a human-reviewed plan.

resource "routeros_interface_list" "office_LAN" {
  router = "office"
  name   = "LAN"
}

resource "routeros_interface_list" "office_WAN" {
  router = "office"
  name   = "WAN"
}

resource "routeros_interface_bridge" "office_bridge" {
  router   = "office"
  name     = "bridge"
  arp      = "enabled"
  mtu      = "auto"
  priority = 32768
}

resource "routeros_interface_bridge_vlan" "office_Trusted" {
  router   = "office"
  bridge   = "bridge"
  comment  = "Trusted"
  vlan_ids = "10"
  tagged   = "ether1,sfp-sfpplus1"
  untagged = "sfp-sfpplus2"
}

resource "routeros_interface_bridge_vlan" "office_Servers" {
  router   = "office"
  bridge   = "bridge"
  comment  = "Servers"
  vlan_ids = "20"
  tagged   = "sfp-sfpplus1,sfp-sfpplus2"
  untagged = ""
}

resource "routeros_interface_bridge_vlan" "office_Guest" {
  router   = "office"
  bridge   = "bridge"
  comment  = "Guest"
  vlan_ids = "30"
  tagged   = "ether1,sfp-sfpplus1"
  untagged = "sfp-sfpplus4"
}

resource "routeros_interface_bridge_vlan" "office_IoT" {
  router   = "office"
  bridge   = "bridge"
  comment  = "IoT"
  vlan_ids = "40"
  tagged   = "ether1,sfp-sfpplus1"
  untagged = ""
}

resource "routeros_interface_bridge_vlan" "office_Video" {
  router   = "office"
  bridge   = "bridge"
  comment  = "Video"
  vlan_ids = "50"
  tagged   = "ether1,sfp-sfpplus1"
  untagged = ""
}

resource "routeros_interface_bridge_port" "office_ether1" {
  router    = "office"
  bridge    = "bridge"
  interface = "ether1"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "office_sfp_sfpplus1" {
  router    = "office"
  bridge    = "bridge"
  interface = "sfp-sfpplus1"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "office_sfp_sfpplus2" {
  router    = "office"
  bridge    = "bridge"
  interface = "sfp-sfpplus2"
  pvid      = 10
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "office_sfp_sfpplus3" {
  router    = "office"
  bridge    = "bridge"
  interface = "sfp-sfpplus3"
  pvid      = 30
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "office_sfp_sfpplus4" {
  router    = "office"
  bridge    = "bridge"
  interface = "sfp-sfpplus4"
  pvid      = 10
  edge      = "auto"
  hw        = true
}

resource "routeros_ip_address" "office_sfp_sfpplus1" {
  router    = "office"
  address   = "10.0.0.4/24"
  interface = "sfp-sfpplus1"
}

resource "routeros_interface_list_member" "office_WAN_ether1" {
  router    = "office"
  list      = "WAN"
  interface = "ether1"
}

resource "routeros_interface_list_member" "office_LAN_sfp_sfpplus1" {
  router    = "office"
  list      = "LAN"
  interface = "sfp-sfpplus1"
}

resource "routeros_interface_list_member" "office_LAN_sfp_sfpplus2" {
  router    = "office"
  list      = "LAN"
  interface = "sfp-sfpplus2"
}

resource "routeros_interface_list_member" "office_LAN_sfp_sfpplus3" {
  router    = "office"
  list      = "LAN"
  interface = "sfp-sfpplus3"
}

resource "routeros_interface_list_member" "office_LAN_sfp_sfpplus4" {
  router    = "office"
  list      = "LAN"
  interface = "sfp-sfpplus4"
}
