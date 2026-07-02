# Kea DHCPv4 — one subnet per VLAN, reservations from my.network.* options.
{config, ...}: let
  n = config.my.network;
  m = n.mac;
in {
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config.interfaces = ["vlan10" "vlan20" "enp3s0" "enp4s0" "vlan40"];

      lease-database = {
        type = "memfile";
        persist = true;
        name = "/var/lib/kea/dhcp4.leases";
      };

      renew-timer = 900;
      rebind-timer = 1800;
      valid-lifetime = 3600;

      subnet4 = [
        # ── trusted — vlan10 (wired) + enp4s0 (ISP AP) — 192.168.1.0/24 ─
        {
          id = 10;
          subnet = "192.168.1.0/24";
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
          reservations = [
            {
              hw-address = m.homeserver;
              ip-address = n.hosts.homeserver_lan;
              hostname = "homeserver";
            }
            {
              hw-address = m.desktop-lan;
              ip-address = n.hosts.desktop_lan;
              hostname = "desktop";
            }
            {
              hw-address = m.desktop-wifi;
              ip-address = n.hosts.desktop_wifi;
              hostname = "desktop-wifi";
            }
            {
              hw-address = m.matebook;
              ip-address = n.hosts.matebook_wifi;
              hostname = "matebook";
            }
            {
              hw-address = m.homeassistant-vm;
              ip-address = n.hosts.homeassistant-vm;
              hostname = "homeassistant";
            }
            {
              hw-address = m.switch-office;
              ip-address = n.infrastructure.switch-office;
              hostname = "switch-office";
            }
            {
              hw-address = m.switch-livingroom;
              ip-address = n.infrastructure.switch-living-room;
              hostname = "switch-livingroom";
            }
            {
              hw-address = m.sophia-s23;
              ip-address = n.mobile.sophia-s23-ultra;
              hostname = "sophia-s23";
            }
            {
              hw-address = m.volodymyr-s23;
              ip-address = n.mobile.volodymyr-s23;
              hostname = "volodymyr-s23";
            }
          ];
        }

        # ── VLAN 20 — iot ───────────────────────────────────────────────
        {
          id = 20;
          subnet = "192.168.20.0/24";
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
          reservations = [
            {
              hw-address = m.alexa;
              ip-address = n.smart-home.alexa-echo-show;
              hostname = "alexa";
            }
            {
              hw-address = m.plug-entrance;
              ip-address = n.smart-home.plugs.entrance;
              hostname = "plug-entrance";
            }
            {
              hw-address = m.plug-salt;
              ip-address = n.smart-home.plugs.salt;
              hostname = "plug-salt";
            }
            {
              hw-address = m.plug-office;
              ip-address = n.smart-home.plugs.office;
              hostname = "plug-office";
            }
            {
              hw-address = m.plug-table;
              ip-address = n.smart-home.plugs.table;
              hostname = "plug-table";
            }
            {
              hw-address = m.plug-window;
              ip-address = n.smart-home.plugs.window;
              hostname = "plug-window";
            }
            {
              hw-address = m.humidifier;
              ip-address = n.smart-home.humidifier;
              hostname = "humidifier";
            }
            # OpenWrt AP — add mac when available
          ];
        }

        # ── media — physical port enp3s0 (no VLAN tagging) ─────────────
        {
          id = 30;
          subnet = "192.168.30.0/24";
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
          reservations = [
            {
              hw-address = m.ps5;
              ip-address = n.entertainment.playstation-5;
              hostname = "ps5";
            }
            {
              hw-address = m.nintendo-switch;
              ip-address = n.entertainment.nintendo-switch;
              hostname = "nintendo-switch";
            }
            {
              hw-address = m.mi-box-s;
              ip-address = n.entertainment.mi-box-s;
              hostname = "mi-box-s";
            }
            {
              hw-address = m.roku-tv;
              ip-address = n.entertainment.roku-tv;
              hostname = "roku-tv";
            }
          ];
        }

        # ── VLAN 40 — work ──────────────────────────────────────────────
        {
          id = 40;
          subnet = "192.168.40.0/24";
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
