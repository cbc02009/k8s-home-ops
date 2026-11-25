# One MikroTik RouterOS switch's L2 config. All boilerplate (the `router`
# key, the bridge name on VLANs/ports/members) lives here, once.
variable "router" {
  type = string
}

variable "lists" {
  type    = map(object({ name = string }))
  default = {}
}

variable "bridge" {
  type = object({
    name              = string
    comment           = optional(string)
    arp               = optional(string)
    mtu               = optional(string)
    priority          = optional(number)
    igmp_snooping     = optional(bool)
    ingress_filtering = optional(bool)
    protocol_mode     = optional(string)
    frame_types       = optional(string)
    forward_delay     = optional(string)
    ageing_time       = optional(string)
    ether_type        = optional(string)
    fast_forward      = optional(bool)
    vlan_filtering    = optional(bool)
    max_message_age   = optional(string)
  })
  default = null
}

variable "vlans" {
  type = map(object({
    vlan_ids = string
    tagged   = optional(string, "")
    untagged = optional(string, "")
    bridge   = optional(string) # defaults to var.bridge.name in main.tofu
  }))
  default = {}
}

variable "ports" {
  type = map(object({
    interface         = string
    comment           = optional(string)
    pvid              = optional(number)
    edge              = optional(string)
    frame_types       = optional(string)
    ingress_filtering = optional(bool)
    hw                = optional(bool)
  }))
  default = {}
}

variable "members" {
  type = map(object({
    list      = string
    interface = string
  }))
  default = {}
}

variable "addresses" {
  type = map(object({
    address   = string
    interface = string
  }))
  default = {}
}
