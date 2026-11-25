# cluster-switch — generated from live inventory via MikroMCP (2026-11-25).
# Import each existing object before the first apply, e.g.:
#   tofu import 'routeros_<type>.<res>' 'cluster/<.id>'
# Applies are gated on a human-reviewed plan.

resource "routeros_interface_list" "cluster_WAN" {
  router = "cluster"
  name   = "WAN"
}

resource "routeros_interface_list" "cluster_LAN" {
  router = "cluster"
  name   = "LAN"
}

resource "routeros_interface_bridge" "cluster_bridge" {
  router   = "cluster"
  name     = "bridge"
  arp      = "enabled"
  mtu      = 9000
  priority = 32768
}

resource "routeros_interface_bridge_vlan" "cluster_SERVERS" {
  router   = "cluster"
  bridge   = "bridge"
  comment  = "SERVERS"
  vlan_ids = "20"
  tagged   = "sfp-sfpplus1"
  untagged = "ether1,ether2,ether3"
}

resource "routeros_interface_bridge_vlan" "cluster_VPN" {
  router   = "cluster"
  bridge   = "bridge"
  comment  = "VPN"
  vlan_ids = "50"
  tagged   = "ether1,ether2,ether3,sfp-sfpplus1"
  untagged = ""
}

resource "routeros_interface_bridge_port" "cluster_ether1" {
  router    = "cluster"
  bridge    = "bridge"
  interface = "ether1"
  pvid      = 20
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "cluster_ether2" {
  router    = "cluster"
  bridge    = "bridge"
  interface = "ether2"
  pvid      = 20
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "cluster_ether3" {
  router    = "cluster"
  bridge    = "bridge"
  interface = "ether3"
  pvid      = 20
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "cluster_ether4" {
  router    = "cluster"
  bridge    = "bridge"
  interface = "ether4"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "cluster_ether5" {
  router    = "cluster"
  bridge    = "bridge"
  interface = "ether5"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "cluster_ether6" {
  router    = "cluster"
  bridge    = "bridge"
  interface = "ether6"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "cluster_ether7" {
  router    = "cluster"
  bridge    = "bridge"
  interface = "ether7"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "cluster_ether8" {
  router    = "cluster"
  bridge    = "bridge"
  interface = "ether8"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "cluster_sfp_sfpplus1" {
  router    = "cluster"
  bridge    = "bridge"
  interface = "sfp-sfpplus1"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_bridge_port" "cluster_sfp_sfpplus2" {
  router    = "cluster"
  bridge    = "bridge"
  interface = "sfp-sfpplus2"
  pvid      = 1
  edge      = "auto"
  hw        = true
}

resource "routeros_interface_list_member" "cluster_WAN_ether1" {
  router    = "cluster"
  list      = "WAN"
  interface = "ether1"
}

resource "routeros_interface_list_member" "cluster_LAN_ether2" {
  router    = "cluster"
  list      = "LAN"
  interface = "ether2"
}

resource "routeros_interface_list_member" "cluster_LAN_ether3" {
  router    = "cluster"
  list      = "LAN"
  interface = "ether3"
}

resource "routeros_interface_list_member" "cluster_LAN_ether4" {
  router    = "cluster"
  list      = "LAN"
  interface = "ether4"
}

resource "routeros_interface_list_member" "cluster_LAN_ether5" {
  router    = "cluster"
  list      = "LAN"
  interface = "ether5"
}

resource "routeros_interface_list_member" "cluster_LAN_ether6" {
  router    = "cluster"
  list      = "LAN"
  interface = "ether6"
}

resource "routeros_interface_list_member" "cluster_LAN_ether7" {
  router    = "cluster"
  list      = "LAN"
  interface = "ether7"
}

resource "routeros_interface_list_member" "cluster_LAN_ether8" {
  router    = "cluster"
  list      = "LAN"
  interface = "ether8"
}

resource "routeros_interface_list_member" "cluster_LAN_sfp_sfpplus1" {
  router    = "cluster"
  list      = "LAN"
  interface = "sfp-sfpplus1"
}

resource "routeros_interface_list_member" "cluster_LAN_sfp_sfpplus2" {
  router    = "cluster"
  list      = "LAN"
  interface = "sfp-sfpplus2"
}
