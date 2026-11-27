# cluster-switch — data only; all resource boilerplate lives in modules/switch.
# Imports: see imports.sh (module.<router>.* addresses).
module "cluster" {
  source = "./modules/switch"
  router = "cluster"

  lists = {
    WAN = {
      name = "WAN"
    }
    LAN = {
      name = "LAN"
    }
  }

  bridge = {
    name     = "bridge"
    comment  = "defconf"
    arp      = "enabled"
    mtu      = 9000
    priority = 32768
  }

  vlans = {
    SERVERS = {
      vlan_ids = "20"
      tagged   = "sfp-sfpplus1"
      untagged = "ether1,ether2,ether3"
    }
    VPN = {
      vlan_ids = "50"
      tagged   = "ether1,ether2,ether3,sfp-sfpplus1"
    }
  }

  ports = {
    ether1 = {
      interface = "ether1"
      pvid      = 20
      edge      = "auto"
      hw        = true
    }
    ether2 = {
      interface = "ether2"
      pvid      = 20
      edge      = "auto"
      hw        = true
    }
    ether3 = {
      interface = "ether3"
      pvid      = 20
      edge      = "auto"
      hw        = true
    }
    ether4 = {
      interface = "ether4"
      pvid      = 1
      edge      = "auto"
      hw        = true
    }
    ether5 = {
      interface = "ether5"
      pvid      = 1
      edge      = "auto"
      hw        = true
    }
    ether6 = {
      interface = "ether6"
      pvid      = 1
      edge      = "auto"
      hw        = true
    }
    ether7 = {
      interface = "ether7"
      pvid      = 1
      edge      = "auto"
      hw        = true
    }
    ether8 = {
      interface = "ether8"
      pvid      = 1
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus1 = {
      interface = "sfp-sfpplus1"
      pvid      = 1
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus2 = {
      interface = "sfp-sfpplus2"
      pvid      = 1
      edge      = "auto"
      hw        = true
    }
  }

  members = {
    WAN_ether1 = {
      list      = "WAN"
      interface = "ether1"
    }
    LAN_ether2 = {
      list      = "LAN"
      interface = "ether2"
    }
    LAN_ether3 = {
      list      = "LAN"
      interface = "ether3"
    }
    LAN_ether4 = {
      list      = "LAN"
      interface = "ether4"
    }
    LAN_ether5 = {
      list      = "LAN"
      interface = "ether5"
    }
    LAN_ether6 = {
      list      = "LAN"
      interface = "ether6"
    }
    LAN_ether7 = {
      list      = "LAN"
      interface = "ether7"
    }
    LAN_ether8 = {
      list      = "LAN"
      interface = "ether8"
    }
    LAN_sfp_sfpplus1 = {
      list      = "LAN"
      interface = "sfp-sfpplus1"
    }
    LAN_sfp_sfpplus2 = {
      list      = "LAN"
      interface = "sfp-sfpplus2"
    }
  }

}
