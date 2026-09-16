# Per-host interface/hardware annotations live in modules/topology/; this file defines
# the global topology. Interface addresses are descriptive labels, not real IPs, so the
# rendered SVGs are safe to commit. Regenerate with `just topology`.
{
  inputs,
  config,
  ...
}: let
  # The VLAN CIDRs are plain `my.network.*` option defaults (not router-specific),
  # so any fully-evaluated host carries the same values.
  net = config.flake.nixosConfigurations.homeserver.config.my.network;
in {
  imports = [inputs.nix-topology.flakeModule];

  perSystem = {
    topology.modules = [
      {
        nixosConfigurations = {
          inherit
            (config.flake.nixosConfigurations)
            desktop
            homeserver
            matebook
            gcp-relay
            ;
        };
      }

      ({config, ...}: let
        inherit (config.lib.topology) mkInternet mkRouter mkSwitch mkDevice mkConnection;
      in {
        networks = {
          trusted = {
            name = "Trusted · VLAN 10";
            cidrv4 = net.subnets.trusted;
          };
          iot = {
            name = "IoT · VLAN 20";
            cidrv4 = net.subnets.iot;
          };
          media = {
            name = "Media · enp3s0 (untagged)";
            cidrv4 = net.subnets.media;
          };
          work = {
            name = "Work · VLAN 40 (isolated)";
            cidrv4 = net.subnets.work;
          };
          tailnet = {
            name = "Headscale tailnet";
            cidrv4 = net.subnets.tailscale;
          };
        };

        nodes.internet = mkInternet {
          connections = [
            (mkConnection "isp-router" "wan")
            (mkConnection "gcp-relay" "ens4")
          ];
        };

        nodes.isp-router = mkRouter "ISP Router" {
          info = "Technicolor NH20T";
          interfaceGroups = [["lan"] ["wan"]];
          connections.lan = mkConnection "router" "enp5s0";
        };

        # Described by hand: the host was removed from the flake but the appliance
        # still anchors the topology.
        nodes.router = mkRouter "🧱 router" {
          info = "Sophos SG110/120 · Intel Atom D525 · 2 GB — config-only, not deployed";
          interfaces = {
            enp5s0 = {
              addresses = ["DHCP (ISP router)"];
              type = "ethernet";
            };
            enp4s0 = {
              addresses = ["802.1Q trunk — vlan10 + vlan20 + vlan40"];
              type = "ethernet";
            };
            enp3s0 = {
              network = "media";
              addresses = ["media gateway"];
              type = "ethernet";
            };
            enp2s0 = {
              network = "trusted";
              addresses = ["trusted gateway"];
              type = "ethernet";
            };
            vlan10 = {
              network = "trusted";
              addresses = ["trusted gateway"];
              virtual = true;
            };
            vlan20 = {
              network = "iot";
              addresses = ["iot gateway"];
              virtual = true;
            };
            vlan40 = {
              network = "work";
              addresses = ["work gateway"];
              virtual = true;
            };
          };
        };

        # 802.1Q isn't representable here, so this switch is drawn as the trusted-VLAN
        # segment it mostly carries; the IoT AP is instead hung off the router's vlan20.
        nodes.switch-office = mkSwitch "Office Switch" {
          info = "TP-Link TL-SG108E · 802.1Q — trunk on port 1";
          interfaceGroups = [["port1" "port2" "port3"]];
          connections = {
            port1 = mkConnection "router" "enp4s0";
            port2 = mkConnection "homeserver" "enp0s31f6";
            port3 = mkConnection "desktop" "enp12s0";
          };
          interfaces.port1.network = "trusted";
        };

        nodes.switch-livingroom = mkSwitch "Living Room Switch" {
          info = "TP-Link TL-SG108E · unmanaged use — all ports untagged";
          interfaceGroups = [["port1" "port2" "port3" "port4" "port5"]];
          connections.port1 = mkConnection "router" "enp3s0";
          interfaces.port1.network = "media";
        };

        nodes.ap-trusted = mkDevice "Trusted Wi-Fi AP" {
          info = "ISP AP — bridged into the trusted VLAN via router enp2s0";
          connections = {
            uplink = mkConnection "router" "enp2s0";
            wifi = mkConnection "matebook" "wifi";
          };
          interfaces.uplink.network = "trusted";
        };

        nodes.ap-iot = mkDevice "IoT Wi-Fi AP" {
          info = "TP-Link AC1750 (OpenWrt) — IoT VLAN, office switch port 8";
          connections.uplink = mkConnection "router" "vlan20";
          interfaces.uplink.network = "iot";
        };
      })
    ];
  };
}
