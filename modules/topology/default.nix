# Interface `addresses` here are deliberately descriptive labels, not real IPs, so the
# rendered SVGs are safe to commit to this public repo.
{
  config,
  lib,
  ...
}: let
  host = config.networking.hostName;

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
  topology.self = lib.mkMerge [
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
        # Extractors dump real backend URLs/IPs/domains; keep the cards, drop the
        # leaky detail so the committed SVG stays IP-/domain-/layout-free.
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
        # caddy's virtualHost key + headscale's `info` are the real domain — drop both.
        caddy.details = lib.mkForce {};
        headscale.info = lib.mkForce "";
        main.hidden = lib.mkForce true;
      };
    })
  ];
}
