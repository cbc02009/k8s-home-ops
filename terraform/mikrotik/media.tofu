# media-switch — data only; all resource boilerplate lives in modules/switch.
# Imports: see imports.sh (module.<router>.* addresses).
module "media" {
  source = "./modules/switch"
  router = "media"

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
    mtu      = "auto"
    priority = 32768
  }

  vlans = {
    Trusted = {
      vlan_ids = "10"
      tagged   = "ether1,sfp-sfpplus1"
      untagged = "sfp-sfpplus2,sfp-sfpplus3"
    }
    Servers = {
      vlan_ids = "20"
      tagged   = "sfp-sfpplus1"
    }
    Guest = {
      vlan_ids = "30"
      tagged   = "ether1,sfp-sfpplus1,sfp-sfpplus3"
    }
    IoT = {
      vlan_ids = "40"
      tagged   = "ether1,sfp-sfpplus1,sfp-sfpplus3"
    }
    Video = {
      vlan_ids = "50"
      tagged   = "ether1,sfp-sfpplus1,sfp-sfpplus3"
    }
  }

  ports = {
    ether1 = {
      interface = "ether1"
      comment   = "defconf"
      pvid      = 1
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus1 = {
      interface = "sfp-sfpplus1"
      comment   = "defconf"
      pvid      = 1
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus2 = {
      interface = "sfp-sfpplus2"
      comment   = "defconf"
      pvid      = 10
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus3 = {
      interface = "sfp-sfpplus3"
      comment   = "defconf"
      pvid      = 1
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus4 = {
      interface = "sfp-sfpplus4"
      comment   = "defconf"
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
    LAN_sfp_sfpplus1 = {
      list      = "LAN"
      interface = "sfp-sfpplus1"
    }
    LAN_sfp_sfpplus2 = {
      list      = "LAN"
      interface = "sfp-sfpplus2"
    }
    LAN_sfp_sfpplus3 = {
      list      = "LAN"
      interface = "sfp-sfpplus3"
    }
    LAN_sfp_sfpplus4 = {
      list      = "LAN"
      interface = "sfp-sfpplus4"
    }
  }

  addresses = {
    sfp_sfpplus1 = {
      address   = "10.0.0.6/24"
      interface = "sfp-sfpplus1"
    }
  }

}
