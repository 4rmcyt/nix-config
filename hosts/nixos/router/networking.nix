# Router networking: systemd-networkd, WAN DHCP, 802.1Q VLAN trunk + physical ports.
#
# Physical layout (Sophos SG110/120, Intel Atom D525, 4x LAN + 1x WAN):
#   enp5s0 — WAN       DHCP from ISP router
#   enp4s0 — trunk  →  TL-SG108E #1 (office): tagged vlan10 + vlan20 + vlan40
#     vlan10  trusted  192.168.1.1/24    wired devices (ports 3-6)
#     vlan20  iot      192.168.20.1/24   AC1750 OpenWrt IoT AP (port 8)
#     vlan40  work     192.168.40.1/24   work port (port 7)
#   enp3s0 — media   192.168.30.1/24  → TL-SG108E #2 (living room), untagged
#   enp2s0 — trusted 192.168.1.1/24   → ISP AP (trusted WiFi), untagged
_: let
  wanInterface = "enp5s0";
  trunkInterface = "enp4s0";
  mediaInterface = "enp3s0";
  apInterface = "enp2s0";
in {
  networking = {
    hostName = "router";
    hostId = "a5ffa043";
    useDHCP = false;
    useNetworkd = true;
    enableIPv6 = false;

    # nftables ruleset is in firewall.nix.
    firewall.enable = false;
  };

  systemd.network = {
    enable = true;

    # ── WAN ─────────────────────────────────────────────────────────────────
    networks."10-wan" = {
      matchConfig.Name = wanInterface;
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = false;
        LinkLocalAddressing = "no";
      };
      dhcpV4Config = {
        UseDNS = false;
        UseNTP = false;
        UseRoutes = true;
      };
    };

    # ── Office trunk → TL-SG108E #1 (no IP — carries tagged VLANs) ─────────
    networks."20-trunk" = {
      matchConfig.Name = trunkInterface;
      networkConfig = {
        DHCP = "no";
        LinkLocalAddressing = "no";
        VLAN = ["vlan10" "vlan20" "vlan40"];
      };
    };

    # ── Media switch port (physical, no VLAN tagging) ────────────────────────
    networks."20-media" = {
      matchConfig.Name = mediaInterface;
      address = ["192.168.30.1/24"];
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = false;
        LinkLocalAddressing = "no";
        IPForward = "ipv4";
      };
    };

    # ── ISP AP port (physical, trusted zone, no VLAN tagging) ───────────────
    networks."20-ap" = {
      matchConfig.Name = apInterface;
      address = ["192.168.1.1/24"];
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = false;
        LinkLocalAddressing = "no";
        IPForward = "ipv4";
      };
    };

    # ── VLAN netdevs (802.1Q sub-interfaces on office trunk) ────────────────
    netdevs."30-vlan10" = {
      netdevConfig = {
        Name = "vlan10";
        Kind = "vlan";
      };
      vlanConfig.Id = 10;
    };
    netdevs."30-vlan20" = {
      netdevConfig = {
        Name = "vlan20";
        Kind = "vlan";
      };
      vlanConfig.Id = 20;
    };
    netdevs."30-vlan40" = {
      netdevConfig = {
        Name = "vlan40";
        Kind = "vlan";
      };
      vlanConfig.Id = 40;
    };

    # ── VLAN 10 — trusted (192.168.1.0/24) ──────────────────────────────────
    networks."40-vlan10" = {
      matchConfig.Name = "vlan10";
      address = ["192.168.1.1/24"];
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = false;
        LinkLocalAddressing = "no";
        IPForward = "ipv4";
      };
    };

    # ── VLAN 20 — iot (192.168.20.0/24) ─────────────────────────────────────
    networks."40-vlan20" = {
      matchConfig.Name = "vlan20";
      address = ["192.168.20.1/24"];
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = false;
        LinkLocalAddressing = "no";
        IPForward = "ipv4";
      };
    };

    # ── VLAN 40 — work (192.168.40.0/24) ────────────────────────────────────
    networks."40-vlan40" = {
      matchConfig.Name = "vlan40";
      address = ["192.168.40.1/24"];
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = false;
        LinkLocalAddressing = "no";
        IPForward = "ipv4";
      };
    };
  };
}
