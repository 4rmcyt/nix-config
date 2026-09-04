# nix-topology per-host annotations.
#
# nix-topology's NixOS module is imported on every host (parts/home-manager-integration.nix),
# and its service extractor picks up most homeserver services automatically. This module adds
# the parts it cannot infer: physical/virtual interfaces (only `router` uses systemd-networkd,
# the rest are NetworkManager/DHCP), network membership and hardware descriptions.
#
# The global topology — internet, ISP router, switches, APs, network CIDRs — lives in
# parts/topology.nix. Build the diagrams with:
#   nix build .#topology.x86_64-linux.config.output
{
  config,
  lib,
  ...
}: let
  net = config.my.network;
  host = config.networking.hostName;

  # tailscale0 overlay interface — every host is on the Headscale tailnet.
  tailnet = {
    tailscale0 = {
      network = "tailnet";
      virtual = true;
      type = "wireguard"; # tailscale is wireguard under the hood; closest icon
      addresses = ["100.64.0.0/10"];
      renderer.hidePhysicalConnections = true;
    };
  };
in {
  # The kea extractor assumes every dhcp4 subnet4 entry carries `.interface`; the
  # router's trusted subnet (id 10) deliberately has none (it is served on both
  # vlan10 and enp2s0). DHCP scopes are modelled by hand here anyway.
  topology.extractors.kea.enable = lib.mkIf (host == "router") false;

  topology.self = lib.mkMerge [
    (lib.mkIf (host == "router") {
      name = "🧱 router";
      hardware.info = "Sophos SG110/120 · Intel Atom D525 · 2 GB — config-only, not yet deployed";
      interfaces =
        {
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
            addresses = [net.vlans.media];
            type = "ethernet";
          };
          enp2s0 = {
            network = "trusted";
            addresses = [net.vlans.trusted];
            type = "ethernet";
          };
          vlan10 = {
            network = "trusted";
            addresses = [net.vlans.trusted];
            virtual = true;
          };
          vlan20 = {
            network = "iot";
            addresses = [net.vlans.iot];
            virtual = true;
          };
          vlan40 = {
            network = "work";
            addresses = [net.vlans.work];
            virtual = true;
          };
        }
        // tailnet;
    })

    (lib.mkIf (host == "homeserver") {
      name = "🗄️ homeserver";
      hardware.info = "Intel i7-9700T · 8-core · ZFS (zroot/zdata/zbackup) — Traefik, media, monitoring, SSO";
      interfaces =
        {
          enp0s31f6 = {
            network = "trusted";
            addresses = [net.hosts.homeserver_lan];
            type = "ethernet";
          };
        }
        // tailnet;
      # The Traefik extractor dumps every http.router and its backend URL into the
      # diagram — including job-kombayn (a multi-user app) and every other route.
      # Drop the enumerated router list; the Traefik service card itself stays.
      services.traefik.details = lib.mkForce {};
    })

    (lib.mkIf (host == "desktop") {
      name = "🖥️ desktop";
      hardware.info = "AMD Zen 4 · NVIDIA · Btrfs — workstation, gaming, libvirt, local LLM";
      interfaces =
        {
          enp12s0 = {
            network = "trusted";
            addresses = [net.hosts.desktop_lan];
            type = "ethernet";
          };
        }
        // tailnet;
    })

    (lib.mkIf (host == "matebook") {
      name = "💻 matebook";
      hardware.info = "AMD Zen 1 laptop · ext4 — portable workstation — config-only, not yet deployed";
      interfaces =
        {
          wifi = {
            network = "trusted";
            addresses = [net.hosts.matebook_wifi];
            type = "wifi";
          };
        }
        // tailnet;
    })

    (lib.mkIf (host == "gcp-relay") {
      name = "☁️ gcp-relay";
      hardware.info = "GCP e2-micro · US Central (Iowa) — Headscale control plane + DERP relay, Caddy TLS";
      interfaces =
        {
          ens4 = {
            addresses = ["GCP static IP"];
            type = "ethernet";
          };
        }
        // tailnet;
    })
  ];
}
