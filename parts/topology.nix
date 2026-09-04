# nix-topology integration via flakeModule.
# Generates topology.${system}.config.output with SVG infrastructure diagrams
# (a physical "main" view and a network-centric view).
#
# Per-host interface/hardware annotations live in modules/topology/ (a NixOS module).
# This file defines the global topology: the internet, the ISP router, the two
# switches, the Wi-Fi APs and the logical network CIDRs.
#
# Interface addresses in modules/topology/ are descriptive labels (not real IPs),
# so the rendered SVGs are safe to commit and are embedded in the README.
# Regenerate with `just topology` (or `nix build .#topology.x86_64-linux.config.output`).
{
  inputs,
  config,
  ...
}: {
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
            router
            ;
        };
      }

      ({config, ...}: let
        inherit (config.lib.topology) mkInternet mkRouter mkSwitch mkDevice mkConnection;
      in {
        networks = {
          trusted = {
            name = "Trusted · VLAN 10";
            cidrv4 = "192.168.1.0/24";
          };
          iot = {
            name = "IoT · VLAN 20";
            cidrv4 = "192.168.20.0/24";
          };
          media = {
            name = "Media · enp3s0 (untagged)";
            cidrv4 = "192.168.30.0/24";
          };
          work = {
            name = "Work · VLAN 40 (isolated)";
            cidrv4 = "192.168.40.0/24";
          };
          tailnet = {
            name = "Headscale tailnet";
            cidrv4 = "100.64.0.0/10";
          };
        };

        # The internet, reached via the ISP router; the GCP relay sits on it too.
        nodes.internet = mkInternet {
          connections = [
            (mkConnection "isp-router" "wan")
            (mkConnection "gcp-relay" "ens4")
          ];
        };

        # ISP-provided gateway — WAN uplink + trusted Wi-Fi AP.
        nodes.isp-router = mkRouter "ISP Router" {
          info = "Technicolor NH20T";
          interfaceGroups = [["lan"] ["wan"]];
          connections.lan = mkConnection "router" "enp5s0";
        };

        # TP-Link TL-SG108E #1 — 802.1Q managed; port 1 is the tagged trunk to the
        # router. 802.1Q is not representable here, so the switch is drawn as the
        # trusted-VLAN segment it mostly carries; the IoT AP on port 8 is instead
        # hung off the router's vlan20 interface below.
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

        # TP-Link TL-SG108E #2 — used unmanaged; all ports one L2 domain.
        nodes.switch-livingroom = mkSwitch "Living Room Switch" {
          info = "TP-Link TL-SG108E · unmanaged use — all ports untagged";
          interfaceGroups = [["port1" "port2" "port3" "port4" "port5"]];
          connections.port1 = mkConnection "router" "enp3s0";
          interfaces.port1.network = "media";
        };

        # Wi-Fi APs.
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
