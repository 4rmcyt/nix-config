{
  lib,
  inputs,
  ...
}: let
  net = inputs.private.lib.network;
in {
  options.my.network = {
    # Gateway (NixOS router, vlan10)
    gateway = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1.1";
      description = "Default gateway — NixOS router, trusted VLAN";
    };

    # VLAN gateway IPs (router's address on each segment)
    vlans = {
      trusted = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.1";
        description = "Router gateway IP — trusted VLAN (vlan10)";
      };
      iot = lib.mkOption {
        type = lib.types.str;
        default = "192.168.20.1";
        description = "Router gateway IP — IoT VLAN (vlan20)";
      };
      media = lib.mkOption {
        type = lib.types.str;
        default = "192.168.30.1";
        description = "Router gateway IP — media segment (enp3s0, physical, no VLAN)";
      };
      work = lib.mkOption {
        type = lib.types.str;
        default = "192.168.40.1";
        description = "Router gateway IP — work VLAN (vlan40)";
      };
    };

    # Primary systems (trusted VLAN)
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

    # Network infrastructure IPs (router, ISP router, managed switches). Keyed
    # attrset from the private flake.
    infrastructure = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = net.infrastructure or {};
      description = "Infrastructure IPs by device key (defined in the private flake).";
    };

    # Full home device inventory — DHCP reservations on the router plus the
    # /etc/hosts and SSH aliases derived from them. Defined in the private
    # flake so device names never land in the public repo. Each entry:
    #   { hostname; mac; ip; subnetId; aliases ? []; }
    reservations = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
      default = net.reservations or [];
      description = "DHCP reservations / host aliases (defined in the private flake).";
    };

    # Network subnets
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

    # Service ports - organized by category
    ports = {
      # Media Services
      jellyfin = lib.mkOption {
        type = lib.types.port;
        default = 8096;
        description = "Jellyfin media server";
      };

      transmission = lib.mkOption {
        type = lib.types.port;
        default = 9091;
        description = "Transmission BitTorrent client web UI";
      };

      audiobookshelf = lib.mkOption {
        type = lib.types.port;
        default = 9292;
        description = "Audiobookshelf audiobook server";
      };

      tdarr = lib.mkOption {
        type = lib.types.port;
        default = 8265;
        description = "Tdarr media transcoding web UI";
      };

      # *arr Media Automation Stack
      sonarr = lib.mkOption {
        type = lib.types.port;
        default = 8990;
        description = "Sonarr TV shows automation";
      };

      radarr = lib.mkOption {
        type = lib.types.port;
        default = 7878;
        description = "Radarr movies automation";
      };

      lidarr = lib.mkOption {
        type = lib.types.port;
        default = 8686;
        description = "Lidarr music automation";
      };

      lazylibrarian = lib.mkOption {
        type = lib.types.port;
        default = 5299;
        description = "LazyLibrarian ebooks/audiobooks automation";
      };

      bazarr = lib.mkOption {
        type = lib.types.port;
        default = 6767;
        description = "Bazarr subtitles automation";
      };

      prowlarr = lib.mkOption {
        type = lib.types.port;
        default = 9696;
        description = "Prowlarr indexer manager";
      };

      # Monitoring & Observability
      prometheus = lib.mkOption {
        type = lib.types.port;
        default = 9090;
        description = "Prometheus time-series database";
      };

      grafana = lib.mkOption {
        type = lib.types.port;
        default = 3003;
        description = "Grafana metrics visualization";
      };

      node-exporter = lib.mkOption {
        type = lib.types.port;
        default = 9100;
        description = "Prometheus node exporter";
      };

      # Productivity & Document Management
      miniflux = lib.mkOption {
        type = lib.types.port;
        default = 8086;
        description = "Miniflux RSS feed reader";
      };

      radicale = lib.mkOption {
        type = lib.types.port;
        default = 5232;
        description = "Radicale CalDAV/CardDAV server";
      };

      homepage = lib.mkOption {
        type = lib.types.port;
        default = 8082;
        description = "Homepage application dashboard";
      };

      # Home Automation
      home-assistant = lib.mkOption {
        type = lib.types.port;
        default = 8123;
        description = "Home Assistant smart home platform";
      };

      mosquitto = lib.mkOption {
        type = lib.types.port;
        default = 1883;
        description = "Mosquitto MQTT broker";
      };

      # Alerting
      alertmanager = lib.mkOption {
        type = lib.types.port;
        default = 9093;
        description = "Prometheus Alertmanager";
      };

      alertmanager-ntfy = lib.mkOption {
        type = lib.types.port;
        default = 9094;
        description = "alertmanager-ntfy bridge";
      };

      # More *arr / media automation
      kapowarr = lib.mkOption {
        type = lib.types.port;
        default = 5656;
        description = "Kapowarr comics automation web UI";
      };

      seerr = lib.mkOption {
        type = lib.types.port;
        default = 5055;
        description = "Jellyseerr request management web UI";
      };

      qb = lib.mkOption {
        type = lib.types.port;
        default = 8081;
        description = "qBittorrent WebUI proxy (host side, forwards into the VPN netns)";
      };

      # Reading / document management
      komf = lib.mkOption {
        type = lib.types.port;
        default = 8085;
        description = "Komf metadata fetcher web UI";
      };

      komga = lib.mkOption {
        type = lib.types.port;
        default = 8087;
        description = "Komga comics/manga server";
      };

      # Utilities
      microbin = lib.mkOption {
        type = lib.types.port;
        default = 8069;
        description = "Microbin pastebin/file-sharing service";
      };

      dispatcharr = lib.mkOption {
        type = lib.types.port;
        default = 9191;
        description = "Dispatcharr IPTV/EPG manager";
      };

      ntfy = lib.mkOption {
        type = lib.types.port;
        default = 9991;
        description = "ntfy push notification server";
      };
    };
  };
}
