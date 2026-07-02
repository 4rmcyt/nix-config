# Router networking: systemd-networkd, WAN DHCP, 802.1Q VLAN trunk, static VLAN gateways.
#
# PLACEHOLDER interface names — fill in after running `ip link` on real hardware:
#   wanInterface      = uplink to ISP router (DHCP client)
#   lanTrunkInterface = 802.1Q trunk to Switch #1 (office/lab TL-SG108E)
#
# To discover real names: boot a NixOS installer, run `ip link`, look for the
# two physical ports. Atom D525 boards typically expose Intel NICs as enp*s*.
_: let
  wanInterface = "enp1s0"; # PLACEHOLDER
  lanTrunkInterface = "enp2s0"; # PLACEHOLDER
in {
  networking = {
    hostName = "router";
    hostId = "a1b2c3d4"; # generate with: head -c 8 /dev/urandom | od -A n -t x4 | tr -d ' \n'
    useDHCP = false;
    useNetworkd = true;
    enableIPv6 = false;

    # nftables ruleset is defined in firewall.nix.
    # Disable the NixOS simple firewall to prevent conflicting rulesets.
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

    # ── LAN trunk (no IP — carries tagged VLANs only) ────────────────────
    networks."20-lan-trunk" = {
      matchConfig.Name = lanTrunkInterface;
      networkConfig = {
        DHCP = "no";
        LinkLocalAddressing = "no";
        # Attach the four VLAN sub-interfaces so networkd brings them up.
        VLAN = ["vlan10" "vlan20" "vlan30" "vlan40"];
      };
    };

    # ── VLAN netdevs (802.1Q sub-interfaces) ─────────────────────────────
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
    netdevs."30-vlan30" = {
      netdevConfig = {
        Name = "vlan30";
        Kind = "vlan";
      };
      vlanConfig.Id = 30;
    };
    netdevs."30-vlan40" = {
      netdevConfig = {
        Name = "vlan40";
        Kind = "vlan";
      };
      vlanConfig.Id = 40;
    };

    # ── VLAN 10 — trusted (192.168.1.0/24, gw 192.168.1.1) ─────────────
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

    # ── VLAN 20 — iot (192.168.20.0/24, gw 192.168.20.1) ───────────────
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

    # ── VLAN 30 — media (192.168.30.0/24, gw 192.168.30.1) ─────────────
    networks."40-vlan30" = {
      matchConfig.Name = "vlan30";
      address = ["192.168.30.1/24"];
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = false;
        LinkLocalAddressing = "no";
        IPForward = "ipv4";
      };
    };

    # ── VLAN 40 — work (192.168.40.0/24, gw 192.168.40.1) ──────────────
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
