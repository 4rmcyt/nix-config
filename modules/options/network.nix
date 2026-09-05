{
  lib,
  inputs,
  ...
}: let
  net = inputs.private.lib.network;

  mkPort = default: description:
    lib.mkOption {
      type = lib.types.port;
      inherit default description;
    };
in {
  options.my.network = {
    gateway = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1.1";
      description = "Default gateway — router appliance, trusted VLAN";
    };

    podmanBridge = lib.mkOption {
      type = lib.types.str;
      default = "podman0";
      description = "Podman default network bridge interface name.";
    };

    podmanGateway = lib.mkOption {
      type = lib.types.str;
      default = "10.88.0.1";
      description = "Podman default network gateway IP — host side of the bridge; host services (redis, postgres) bind it.";
    };

    hosts = {
      homeserver_lan = lib.mkOption {
        type = lib.types.str;
        default = net.hosts.homeserver_lan;
        description = "IP address of homeserver — trusted VLAN";
      };

      desktop_lan = lib.mkOption {
        type = lib.types.str;
        default = net.hosts.desktop_lan;
        description = "IP address of desktop wired — trusted VLAN";
      };

      desktop_wifi = lib.mkOption {
        type = lib.types.str;
        default = net.hosts.desktop_wifi;
        description = "IP address of desktop wireless — trusted VLAN";
      };

      matebook_wifi = lib.mkOption {
        type = lib.types.str;
        default = net.hosts.matebook_wifi;
        description = "IP address of Matebook wireless — trusted VLAN";
      };

      homeassistant-vm = lib.mkOption {
        type = lib.types.str;
        default = net.hosts."homeassistant-vm";
        description = "Home Assistant VM (QEMU on homeserver) — trusted VLAN";
      };

      # Tailscale (tailnet) addresses — CGNAT range, not modeled in the
      # private flake since they're only reachable over the tailnet itself.
      desktop_ts = lib.mkOption {
        type = lib.types.str;
        default = "100.64.0.1";
        description = "IP address of desktop — Tailscale/Headscale tailnet";
      };

      homeserver_ts = lib.mkOption {
        type = lib.types.str;
        default = "100.64.0.3";
        description = "IP address of homeserver — Tailscale/Headscale tailnet";
      };

      matebook_ts = lib.mkOption {
        type = lib.types.str;
        default = "100.64.0.4";
        description = "IP address of Matebook — Tailscale/Headscale tailnet";
      };

      gcp-relay_ts = lib.mkOption {
        type = lib.types.str;
        default = "100.64.0.5";
        description = "IP address of gcp-relay — Tailscale/Headscale tailnet";
      };
    };

    # MAC addresses referenced outside the DHCP reservation list (currently just
    # the desktop Wi-Fi NIC, for a udev naming rule). Keyed attrset from the
    # private flake.
    mac = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = net.mac or {};
      description = "MAC addresses by device key (defined in the private flake).";
    };

    infrastructure = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = net.infrastructure or {};
      description = "Infrastructure IPs by device key (defined in the private flake).";
    };

    # Full home device inventory — drives the /etc/hosts and SSH aliases
    # derived from it. Defined in the private
    # flake so device names never land in the public repo. Each entry:
    #   { hostname; mac; ip; subnetId; aliases ? []; }
    reservations = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
      default = net.reservations or [];
      description = "DHCP reservations / host aliases (defined in the private flake).";
    };

    subnets = {
      lan = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "192.168.1.0/24"
          "192.168.0.0/24"
        ];
        description = "Local area network subnets";
      };

      tailscale = lib.mkOption {
        type = lib.types.str;
        default = "100.64.0.0/10";
        description = "Tailscale VPN network subnet";
      };

      trusted = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.0/24";
        description = "Trusted VLAN subnet (vlan10)";
      };

      iot = lib.mkOption {
        type = lib.types.str;
        default = "192.168.20.0/24";
        description = "IoT VLAN subnet (vlan20)";
      };

      media = lib.mkOption {
        type = lib.types.str;
        default = "192.168.30.0/24";
        description = "Media segment subnet (enp3s0, physical, no VLAN)";
      };

      work = lib.mkOption {
        type = lib.types.str;
        default = "192.168.40.0/24";
        description = "Work VLAN subnet (vlan40)";
      };

      podman = lib.mkOption {
        type = lib.types.str;
        default = "10.88.0.0/16";
        description = "Podman container network subnet";
      };

      private = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
        ];
        description = "Private network ranges (RFC1918)";
      };

      cloudflare = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "173.245.48.0/20"
          "103.21.244.0/22"
          "103.22.200.0/22"
          "103.31.4.0/22"
          "141.101.64.0/18"
          "108.162.192.0/18"
          "190.93.240.0/20"
          "188.114.96.0/20"
          "197.234.240.0/22"
          "198.41.128.0/17"
          "162.158.0.0/15"
          "104.16.0.0/13"
          "104.24.0.0/14"
          "172.64.0.0/13"
          "131.0.72.0/22"
        ];
        description = "Cloudflare IPv4 proxy ranges (https://www.cloudflare.com/ips-v4)";
      };
    };

    ports = {
      jellyfin = mkPort 8096 "Jellyfin media server";
      transmission = mkPort 9091 "Transmission BitTorrent client web UI";
      audiobookshelf = mkPort 9292 "Audiobookshelf audiobook server";
      tdarr = mkPort 8265 "Tdarr media transcoding web UI";

      sonarr = mkPort 8990 "Sonarr TV shows automation";
      radarr = mkPort 7878 "Radarr movies automation";
      lidarr = mkPort 8686 "Lidarr music automation";
      lazylibrarian = mkPort 5299 "LazyLibrarian ebooks/audiobooks automation";
      bazarr = mkPort 6767 "Bazarr subtitles automation";
      prowlarr = mkPort 9696 "Prowlarr indexer manager";

      prometheus = mkPort 9090 "Prometheus time-series database";
      grafana = mkPort 3003 "Grafana metrics visualization";
      loki = mkPort 3100 "Loki log aggregation server";
      node-exporter = mkPort 9100 "Prometheus node exporter";
      traefik-metrics = mkPort 8080 "Traefik Prometheus metrics entrypoint (localhost only)";

      miniflux = mkPort 8086 "Miniflux RSS feed reader";
      radicale = mkPort 5232 "Radicale CalDAV/CardDAV server";
      homepage = mkPort 8082 "Homepage application dashboard";

      home-assistant = mkPort 8123 "Home Assistant smart home platform";
      mosquitto = mkPort 1883 "Mosquitto MQTT broker";

      alertmanager = mkPort 9093 "Prometheus Alertmanager";
      alertmanager-ntfy = mkPort 9094 "alertmanager-ntfy bridge";

      kapowarr = mkPort 5656 "Kapowarr comics automation web UI";
      seerr = mkPort 5055 "Jellyseerr request management web UI";
      qb = mkPort 8081 "qBittorrent WebUI proxy (host side, forwards into the VPN netns)";

      komf = mkPort 8085 "Komf metadata fetcher web UI";
      komga = mkPort 8087 "Komga comics/manga server";

      microbin = mkPort 8069 "Microbin pastebin/file-sharing service";
      dispatcharr = mkPort 9191 "Dispatcharr IPTV/EPG manager";
      ntfy = mkPort 9991 "ntfy push notification server";

      crowdsec-lapi = mkPort 8088 "CrowdSec local API (LAPI) — local bouncers plus the gcp-relay remote bouncer over Tailscale";
      traefik-api = mkPort 8083 "Traefik API entrypoint (localhost only, used by the homepage widget)";

      atuin = mkPort 8881 "Atuin shell history sync server";
      nut = mkPort 3493 "Network UPS Tools (NUT) upsd server";
    };
  };
}
