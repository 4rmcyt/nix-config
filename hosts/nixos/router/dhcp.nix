# Kea DHCPv4 server — one subnet per VLAN, static bindings by MAC.
#
# Subnets:
#   VLAN 10 trusted  192.168.1.0/24    pool .100-.200   gw .1
#   VLAN 20 iot      192.168.20.0/24   pool .100-.200   gw .20.1
#   VLAN 30 media    192.168.30.0/24   pool .100-.200   gw .30.1
#   VLAN 40 work     192.168.40.0/24   pool .100-.200   gw .40.1
#
# Static bindings: fill in real MAC addresses below.
# Format: "aa:bb:cc:dd:ee:ff"
#
# DNS: Unbound on homeserver (192.168.1.165) serves split DNS for *.example.com.
# If you move DNS to the router later, change dns-servers below to 192.168.1.1.
{ ... }: {
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config.interfaces = [ "vlan10" "vlan20" "vlan30" "vlan40" ];

      lease-database = {
        type    = "memfile";
        persist = true;
        name    = "/var/lib/kea/dhcp4.leases";
      };

      renew-timer   = 900;
      rebind-timer  = 1800;
      valid-lifetime = 3600;

      subnet4 = [
        # ── VLAN 10 — trusted ───────────────────────────────────────────
        {
          id     = 10;
          subnet = "192.168.1.0/24";
          interface = "vlan10";
          pools  = [{ pool = "192.168.1.100 - 192.168.1.200"; }];
          option-data = [
            { name = "routers";              data = "192.168.1.1"; }
            { name = "domain-name-servers";  data = "192.168.1.165"; }  # homeserver unbound
            { name = "broadcast-address";    data = "192.168.1.255"; }
          ];
          reservations = [
            # PLACEHOLDER — add entries per device:
            # { hw-address = "aa:bb:cc:dd:ee:ff"; ip-address = "192.168.1.165"; hostname = "homeserver"; }
            # { hw-address = "aa:bb:cc:dd:ee:ff"; ip-address = "192.168.1.118"; hostname = "desktop"; }
            # { hw-address = "aa:bb:cc:dd:ee:ff"; ip-address = "192.168.1.132"; hostname = "matebook"; }
          ];
        }

        # ── VLAN 20 — iot ───────────────────────────────────────────────
        {
          id     = 20;
          subnet = "192.168.20.0/24";
          interface = "vlan20";
          pools  = [{ pool = "192.168.20.100 - 192.168.20.200"; }];
          option-data = [
            { name = "routers";             data = "192.168.20.1"; }
            { name = "domain-name-servers"; data = "192.168.1.165"; }
            { name = "broadcast-address";   data = "192.168.20.255"; }
          ];
          reservations = [
            # PLACEHOLDER
            # { hw-address = "aa:bb:cc:dd:ee:ff"; ip-address = "192.168.20.10"; hostname = "openwrt-ap"; }
          ];
        }

        # ── VLAN 30 — media ─────────────────────────────────────────────
        {
          id     = 30;
          subnet = "192.168.30.0/24";
          interface = "vlan30";
          pools  = [{ pool = "192.168.30.100 - 192.168.30.200"; }]; 
          option-data = [
            { name = "routers";             data = "192.168.30.1"; }
            { name = "domain-name-servers"; data = "192.168.1.165"; }
            { name = "broadcast-address";   data = "192.168.30.255"; }
          ];
          reservations = [
            # PLACEHOLDER
            # { hw-address = "aa:bb:cc:dd:ee:ff"; ip-address = "192.168.30.10"; hostname = "roku-tv"; }
            # { hw-address = "aa:bb:cc:dd:ee:ff"; ip-address = "192.168.30.11"; hostname = "ps5"; }
          ];
        }

        # ── VLAN 40 — work ──────────────────────────────────────────────
        {
          id     = 40;
          subnet = "192.168.40.0/24";
          interface = "vlan40";
          pools  = [{ pool = "192.168.40.100 - 192.168.40.200"; }];
          option-data = [
            { name = "routers";             data = "192.168.40.1"; }
            # work VLAN isolated — no LAN DNS, use public resolver
            { name = "domain-name-servers"; data = "1.1.1.1"; }
            { name = "broadcast-address";   data = "192.168.40.255"; }
          ];
          reservations = [
            # PLACEHOLDER
            # { hw-address = "aa:bb:cc:dd:ee:ff"; ip-address = "192.168.40.10"; hostname = "work-laptop"; }
          ];
        }
      ];
    };
  };
}
