provider "routeros" {
  hosturl  = "https://office-switch.ctec.run"
  username = data.doppler_secrets.this.map.USER
  password = data.doppler_secrets.this.map.PASS
}

resource "routeros_interface_ethernet_switch" "sw0" {
  name      = "switch"
  l3_hw_offloading = true
}

# resource "routeros_interface_bridge" "os_bridge" {
#   provider = routeros.office_switch
#   name           = "bridge"
#   vlan_filtering = true
# }

# resource "routeros_interface_ethernet" "test" {
#   provider = routeros.office_switch
#   factory_name = "sfp-sfpplus8"
#   name         = "swtich-eth0"
#   mtu          = 9000
# }
