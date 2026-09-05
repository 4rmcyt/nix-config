# Kea DHCPv4 — one subnet per VLAN. Reservations come from
# my.network.reservations (defined in the private flake).
{
  config,
  lib,
  ...
}: let
  n = config.my.network;
  reservationsFor = id:
    map (r: {
      hw-address = r.mac;
      ip-address = r.ip;
      inherit (r) hostname;
    }) (lib.filter (r: r.subnetId == id) n.reservations);
in {
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = ["vlan10" "vlan20" "enp3s0" "enp2s0" "vlan40"];
        dhcp-socket-type = "raw";
      };

      lease-database = {
        type = "memfile";
        persist = true;
        name = "/var/lib/kea/dhcp4.leases";
      };

      renew-timer = 900;
      rebind-timer = 1800;
      valid-lifetime = 3600;

      subnet4 = [
        # ── trusted — vlan10 (wired) + enp2s0 (ISP AP) — 192.168.1.0/24 ─
        {
          id = 10;
          subnet = n.subnets.trusted;
          # no interface restriction — serves both vlan10 and enp4s0
          pools = [{pool = "192.168.1.100 - 192.168.1.200";}];
          option-data = [
            {
              name = "routers";
              data = n.vlans.trusted;
            }
            {
              name = "domain-name-servers";
              data = n.vlans.trusted;
            }
            {
              name = "broadcast-address";
              data = "192.168.1.255";
            }
          ];
          reservations = reservationsFor 10;
        }

        # ── VLAN 20 — iot ───────────────────────────────────────────────
        {
          id = 20;
          subnet = n.subnets.iot;
          interface = "vlan20";
          pools = [{pool = "192.168.20.100 - 192.168.20.200";}];
          option-data = [
            {
              name = "routers";
              data = n.vlans.iot;
            }
            {
              name = "domain-name-servers";
              data = n.vlans.iot;
            }
            {
              name = "broadcast-address";
              data = "192.168.20.255";
            }
          ];
          # OpenWrt AP — add to my.network.reservations when its mac is known
          reservations = reservationsFor 20;
        }

        # ── media — physical port enp3s0 (no VLAN tagging) ─────────────
        {
          id = 30;
          subnet = n.subnets.media;
          interface = "enp3s0";
          pools = [{pool = "192.168.30.100 - 192.168.30.200";}];
          option-data = [
            {
              name = "routers";
              data = n.vlans.media;
            }
            {
              name = "domain-name-servers";
              data = n.vlans.media;
            }
            {
              name = "broadcast-address";
              data = "192.168.30.255";
            }
          ];
          reservations = reservationsFor 30;
        }

        # ── VLAN 40 — work ──────────────────────────────────────────────
        {
          id = 40;
          subnet = n.subnets.work;
          interface = "vlan40";
          pools = [{pool = "192.168.40.100 - 192.168.40.200";}];
          option-data = [
            {
              name = "routers";
              data = n.vlans.work;
            }
            # work is isolated — direct public DNS, no LAN resolver
            {
              name = "domain-name-servers";
              data = "1.1.1.1";
            }
            {
              name = "broadcast-address";
              data = "192.168.40.255";
            }
          ];
          reservations = [
            # Work laptop — add mac when available
          ];
        }
      ];
    };
  };
}
