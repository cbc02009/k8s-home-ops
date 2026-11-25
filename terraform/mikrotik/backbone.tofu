# backbone-switch — data only; all resource boilerplate lives in modules/switch.
# Imports: see imports.sh (module.<router>.* addresses).
module "backbone" {
  source = "./modules/switch"
  router = "backbone"

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
    arp      = "enabled"
    mtu      = 9000
    priority = 32768
  }

  vlans = {
    TRUSTED = {
      vlan_ids = "10"
      tagged   = "sfp-sfpplus3,bonding-css326,sfp-sfpplus1,sfp-sfpplus4,sfp-sfpplus2,sfp-sfpplus6"
    }
    SERVERS = {
      vlan_ids = "20"
      tagged   = "bonding-css326,sfp-sfpplus1,sfp-sfpplus2,sfp-sfpplus6,sfp-sfpplus3"
      untagged = "sfp-sfpplus8,sfp-sfpplus10,sfp-sfpplus12,bonding-shana"
    }
    GUEST = {
      vlan_ids = "30"
      tagged   = "bonding-css326,sfp-sfpplus2,sfp-sfpplus3,sfp-sfpplus4,sfp-sfpplus1,sfp-sfpplus6"
    }
    vlan40 = {
      vlan_ids = "40"
      tagged   = "bonding-css326,sfp-sfpplus2,sfp-sfpplus3,sfp-sfpplus4,sfp-sfpplus1,sfp-sfpplus6"
    }
    VPN = {
      vlan_ids = "50"
      tagged   = "sfp-sfpplus3,bonding-shana,bonding-css326,sfp-sfpplus4,sfp-sfpplus1,sfp-sfpplus10,sfp-sfpplus11,sfp-sfpplus12"
    }
    Containers = {
      vlan_ids = "60"
      tagged   = "bonding-shana,sfp-sfpplus1"
    }
  }

  ports = {
    ether1 = {
      interface = "ether1"
      pvid      = 1
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus3 = {
      interface = "sfp-sfpplus3"
      pvid      = 1
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus4 = {
      interface = "sfp-sfpplus4"
      pvid      = 1
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus5 = {
      interface = "sfp-sfpplus5"
      pvid      = 20
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus6 = {
      interface = "sfp-sfpplus6"
      pvid      = 1
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus7 = {
      interface = "sfp-sfpplus7"
      pvid      = 1
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus8 = {
      interface = "sfp-sfpplus8"
      pvid      = 20
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus9 = {
      interface = "sfp-sfpplus9"
      comment   = "Mayne"
      pvid      = 20
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus10 = {
      interface = "sfp-sfpplus10"
      pvid      = 20
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus11 = {
      interface = "sfp-sfpplus11"
      pvid      = 20
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus12 = {
      interface = "sfp-sfpplus12"
      pvid      = 20
      edge      = "auto"
      hw        = true
    }
    bonding_shana = {
      interface = "bonding-shana"
      pvid      = 20
      edge      = "auto"
      hw        = true
    }
    bonding_css326 = {
      interface = "bonding-css326"
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
    sfp_sfpplus13 = {
      interface = "sfp-sfpplus13"
      pvid      = 1
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus14 = {
      interface = "sfp-sfpplus14"
      pvid      = 1
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus15 = {
      interface = "sfp-sfpplus15"
      pvid      = 1
      edge      = "auto"
      hw        = true
    }
    sfp_sfpplus16 = {
      interface = "sfp-sfpplus16"
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
    LAN_sfp_sfpplus5 = {
      list      = "LAN"
      interface = "sfp-sfpplus5"
    }
    LAN_sfp_sfpplus6 = {
      list      = "LAN"
      interface = "sfp-sfpplus6"
    }
    LAN_sfp_sfpplus7 = {
      list      = "LAN"
      interface = "sfp-sfpplus7"
    }
    LAN_sfp_sfpplus8 = {
      list      = "LAN"
      interface = "sfp-sfpplus8"
    }
    LAN_sfp_sfpplus9 = {
      list      = "LAN"
      interface = "sfp-sfpplus9"
    }
    LAN_sfp_sfpplus10 = {
      list      = "LAN"
      interface = "sfp-sfpplus10"
    }
    LAN_sfp_sfpplus11 = {
      list      = "LAN"
      interface = "sfp-sfpplus11"
    }
    LAN_sfp_sfpplus12 = {
      list      = "LAN"
      interface = "sfp-sfpplus12"
    }
    LAN_sfp_sfpplus13 = {
      list      = "LAN"
      interface = "sfp-sfpplus13"
    }
    LAN_sfp_sfpplus14 = {
      list      = "LAN"
      interface = "sfp-sfpplus14"
    }
    LAN_sfp_sfpplus15 = {
      list      = "LAN"
      interface = "sfp-sfpplus15"
    }
    LAN_sfp_sfpplus16 = {
      list      = "LAN"
      interface = "sfp-sfpplus16"
    }
  }

}
