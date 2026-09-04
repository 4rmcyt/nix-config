# nix-topology per-host annotations.
#
# nix-topology's NixOS module is imported on every host (parts/home-manager-integration.nix),
# and its service extractor picks up most homeserver services automatically. This module adds
# the parts it cannot infer: physical/virtual interfaces (only `router` uses systemd-networkd,
# the rest are NetworkManager/DHCP), network membership and hardware descriptions.
#
# Interface `addresses` here are deliberately descriptive labels, not real IPs, so the
# rendered SVGs are safe to commit to this public repo — they expose nothing beyond
# docs/Infrastructure.md (hostnames, interface names, /24 CIDRs, device models).
#
# The global topology — internet, ISP router, switches, APs, network CIDRs — lives in
# parts/topology.nix. Build the diagrams with `just topology`.
{
  config,
  lib,
  ...
}: let
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
        }
        // tailnet;
    })

    (lib.mkIf (host == "homeserver") {
      name = "🗄️ homeserver";
      hardware.info = "Intel Coffee Lake · 8-core · ZFS (zroot/zdata/zbackup) — Traefik, media, monitoring, SSO";
      interfaces =
        {
          enp0s31f6 = {
            network = "trusted";
            addresses = ["static · trusted VLAN"];
            type = "ethernet";
          };
        }
        // tailnet;
      services = {
        # The Traefik extractor dumps every http.router + backend URL (job-kombayn
        # included); the restic extractor dumps the full backup path inventory;
        # mosquitto's listener binds the real LAN IP; grafana/kanidm expose the
        # real domain in `info`. Keep the cards, drop the leaky detail so the
        # committed SVG stays IP-/domain-/layout-free.
        traefik.details = lib.mkForce {};
        mosquitto.details = lib.mkForce {};
        grafana.info = lib.mkForce "";
        kanidm.info = lib.mkForce "";
        local.hidden = lib.mkForce true;
        main.hidden = lib.mkForce true;
      };
    })

    (lib.mkIf (host == "desktop") {
      name = "🖥️ desktop";
      hardware.info = "AMD Zen 4 · NVIDIA · Btrfs — workstation, gaming, libvirt, local LLM";
      interfaces =
        {
          enp12s0 = {
            network = "trusted";
            addresses = ["static · trusted VLAN"];
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
            addresses = ["static · trusted VLAN"];
            type = "wifi";
          };
        }
        // tailnet;
    })

    (lib.mkIf (host == "gcp-relay") {
      name = "☁️ gcp-relay";
      hardware.info = "GCP e2-micro — Headscale control plane + DERP relay, Caddy TLS";
      interfaces =
        {
          ens4 = {
            addresses = ["GCP static IP"];
            type = "ethernet";
          };
        }
        // tailnet;
      services = {
        # caddy's virtualHost key + headscale's `info` are the real domain; restic
        # dumps its backup paths. Drop all three from the committed SVG.
        caddy.details = lib.mkForce {};
        headscale.info = lib.mkForce "";
        main.hidden = lib.mkForce true;
      };
    })
  ];
}
