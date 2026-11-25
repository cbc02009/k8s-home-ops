# backbone-switch — generated from live inventory via MikroMCP (2026-11-25).
# Import each existing object before the first apply, e.g.:
#   tofu import 'routeros_<type>.<res>' 'backbone/<.id>'
# Applies are gated on a human-reviewed plan.

resource "routeros_interface_list" "backbone_WAN" {
  router = "backbone"
  name   = "WAN"
}

resource "routeros_interface_list" "backbone_LAN" {
  router = "backbone"
  name   = "LAN"
}

resource "routeros_interface_bridge" "backbone_bridge" {
  router   = "backbone"
  name     = "bridge"
  arp      = "enabled"
  mtu      = 9000
  priority = 32768
}

resource "routeros_interface_bridge_vlan" "backbone_TRUSTED" {
  router   = "backbone"
  bridge   = "bridge"
  comment  = "TRUSTED"
  vlan_ids = "10"
  tagged   = "sfp-sfpplus3,bonding-css326,sfp-sfpplus1,sfp-sfpplus4,sfp-sfpplus2,sfp-sfpplus6"
  untagged = ""
}

resource "routeros_interface_bridge_vlan" "backbone_SERVERS" {
  router   = "backbone"
  bridge   = "bridge"
  comment  = "SERVERS"
  vlan_ids = "20"
  tagged   = "bonding-css326,sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus6,sfp-sfpplus3"
  untagged = "sfp-sfpplus8,sfp-sfpplus10,sfp-sfpplus12,bonding-shana"
}

resource "routeros_interface_bridge_vlan" "backbone_GUEST" {
  router   = "backbone"
  bridge   = "bridge"
  comment  = "GUEST"
  vlan_ids = "30"
  tagged   = "bonding-css326,sfp-sfpplus2,sfp-sfpplus3,sfp-sfpplus4,sfp-sfpplus1,sfp-sfpplus6"
  untagged = ""
}

resource "routeros_interface_bridge_vlan" "backbone_vlan40" {
  router   = "backbone"
  bridge   = "bridge"
  comment  = "vlan40"
  vlan_ids = "40"
  tagged   = "bonding-css326,sfp-sfpplus2,sfp-sfpplus3,sfp-sfpplus4,sfp-sfpplus1,sfp-sfpplus6"
  untagged = ""
}

resource "routeros_interface_bridge_vlan" "backbone_VPN" {
  router   = "backbone"
  bridge   = "bridge"
  comment  = "VPN"
  vlan_ids = "50"
  tagged   = "sfp-sfpplus3,bonding-shana,bonding-css326,sfp-sfpplus4,sfp-sfpplus1,sfp-sfpplus10,sfp-sfpplus11,sfp-sfpplus12"
  untagged = ""
}

resource "routeros_interface_bridge_vlan" "backbone_Containers" {
  router   = "backbone"
  bridge   = "bridge"
  comment  = "Containers"
  vlan_ids = "60"
  tagged   = "bonding-shana,sfp-sfpplus1"
  untagged = ""
}

resource "routeros_interface_bridge_port" "backbone_ether1" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "ether1"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "backbone_sfp_sfpplus3" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "sfp-sfpplus3"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "backbone_sfp_sfpplus4" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "sfp-sfpplus4"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "backbone_sfp_sfpplus5" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "sfp-sfpplus5"
  pvid      = 20
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "backbone_sfp_sfpplus6" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "sfp-sfpplus6"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "backbone_sfp_sfpplus7" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "sfp-sfpplus7"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "backbone_sfp_sfpplus8" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "sfp-sfpplus8"
  pvid      = 20
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "backbone_sfp_sfpplus9" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "sfp-sfpplus9"
  pvid      = 20
  comment   = "Mayne"
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "backbone_sfp_sfpplus10" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "sfp-sfpplus10"
  pvid      = 20
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "backbone_sfp_sfpplus11" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "sfp-sfpplus11"
  pvid      = 20
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "backbone_sfp_sfpplus12" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "sfp-sfpplus12"
  pvid      = 20
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "backbone_bonding_shana" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "bonding-shana"
  pvid      = 20
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "backbone_bonding_css326" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "bonding-css326"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "backbone_sfp_sfpplus1" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "sfp-sfpplus1"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "backbone_sfp_sfpplus2" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "sfp-sfpplus2"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "backbone_sfp_sfpplus13" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "sfp-sfpplus13"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "backbone_sfp_sfpplus14" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "sfp-sfpplus14"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "backbone_sfp_sfpplus15" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "sfp-sfpplus15"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "backbone_sfp_sfpplus16" {
  router    = "backbone"
  bridge    = "bridge"
  interface = "sfp-sfpplus16"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_list_member" "backbone_WAN_ether1" {
  router    = "backbone"
  list      = "WAN"
  interface = "ether1"
}

resource "routeros_interface_list_member" "backbone_LAN_sfp_sfpplus1" {
  router    = "backbone"
  list      = "LAN"
  interface = "sfp-sfpplus1"
}

resource "routeros_interface_list_member" "backbone_LAN_sfp_sfpplus2" {
  router    = "backbone"
  list      = "LAN"
  interface = "sfp-sfpplus2"
}

resource "routeros_interface_list_member" "backbone_LAN_sfp_sfpplus3" {
  router    = "backbone"
  list      = "LAN"
  interface = "sfp-sfpplus3"
}

resource "routeros_interface_list_member" "backbone_LAN_sfp_sfpplus4" {
  router    = "backbone"
  list      = "LAN"
  interface = "sfp-sfpplus4"
}

resource "routeros_interface_list_member" "backbone_LAN_sfp_sfpplus5" {
  router    = "backbone"
  list      = "LAN"
  interface = "sfp-sfpplus5"
}

resource "routeros_interface_list_member" "backbone_LAN_sfp_sfpplus6" {
  router    = "backbone"
  list      = "LAN"
  interface = "sfp-sfpplus6"
}

resource "routeros_interface_list_member" "backbone_LAN_sfp_sfpplus7" {
  router    = "backbone"
  list      = "LAN"
  interface = "sfp-sfpplus7"
}

resource "routeros_interface_list_member" "backbone_LAN_sfp_sfpplus8" {
  router    = "backbone"
  list      = "LAN"
  interface = "sfp-sfpplus8"
}

resource "routeros_interface_list_member" "backbone_LAN_sfp_sfpplus9" {
  router    = "backbone"
  list      = "LAN"
  interface = "sfp-sfpplus9"
}

resource "routeros_interface_list_member" "backbone_LAN_sfp_sfpplus10" {
  router    = "backbone"
  list      = "LAN"
  interface = "sfp-sfpplus10"
}

resource "routeros_interface_list_member" "backbone_LAN_sfp_sfpplus11" {
  router    = "backbone"
  list      = "LAN"
  interface = "sfp-sfpplus11"
}

resource "routeros_interface_list_member" "backbone_LAN_sfp_sfpplus12" {
  router    = "backbone"
  list      = "LAN"
  interface = "sfp-sfpplus12"
}

resource "routeros_interface_list_member" "backbone_LAN_sfp_sfpplus13" {
  router    = "backbone"
  list      = "LAN"
  interface = "sfp-sfpplus13"
}

resource "routeros_interface_list_member" "backbone_LAN_sfp_sfpplus14" {
  router    = "backbone"
  list      = "LAN"
  interface = "sfp-sfpplus14"
}

resource "routeros_interface_list_member" "backbone_LAN_sfp_sfpplus15" {
  router    = "backbone"
  list      = "LAN"
  interface = "sfp-sfpplus15"
}

resource "routeros_interface_list_member" "backbone_LAN_sfp_sfpplus16" {
  router    = "backbone"
  list      = "LAN"
  interface = "sfp-sfpplus16"
}
