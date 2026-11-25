terraform {
  required_providers {
    routeros = {
      source = "registry.terraform.io/ebogdum/routeros"
    }
  }
}

locals {
  bridge_name = var.bridge != null ? var.bridge.name : "bridge"
}

resource "routeros_interface_list" "lists" {
  for_each = var.lists
  router   = var.router
  name     = each.value.name
}

resource "routeros_interface_bridge" "bridge" {
  count = var.bridge != null ? 1 : 0

  router = var.router
  name   = var.bridge.name

  comment           = var.bridge.comment
  arp               = var.bridge.arp
  mtu               = var.bridge.mtu
  priority          = var.bridge.priority
  igmp_snooping     = var.bridge.igmp_snooping
  ingress_filtering = var.bridge.ingress_filtering
  protocol_mode     = var.bridge.protocol_mode
  frame_types       = var.bridge.frame_types
  forward_delay     = var.bridge.forward_delay
  ageing_time       = var.bridge.ageing_time
  ether_type        = var.bridge.ether_type
  fast_forward      = var.bridge.fast_forward
  vlan_filtering    = var.bridge.vlan_filtering
  max_message_age   = var.bridge.max_message_age
}

resource "routeros_interface_bridge_vlan" "vlans" {
  for_each = var.vlans
  router   = var.router
  bridge   = coalesce(each.value.bridge, local.bridge_name)
  comment  = each.key
  vlan_ids = each.value.vlan_ids
  tagged   = each.value.tagged
  untagged = each.value.untagged
}

resource "routeros_interface_bridge_port" "ports" {
  for_each = var.ports
  router   = var.router
  bridge   = local.bridge_name

  interface         = each.value.interface
  comment           = each.value.comment
  pvid              = each.value.pvid
  edge              = each.value.edge
  frame_types       = each.value.frame_types
  ingress_filtering = each.value.ingress_filtering
  hw                = each.value.hw
}

resource "routeros_interface_list_member" "members" {
  for_each  = var.members
  router    = var.router
  list      = each.value.list
  interface = each.value.interface
}

resource "routeros_ip_address" "addresses" {
  for_each  = var.addresses
  router    = var.router
  address   = each.value.address
  interface = each.value.interface
}
