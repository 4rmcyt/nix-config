{
  lib,
  inputs,
  ...
}: let
  net = inputs.private.lib.network;

  # Service ports plus their exposure class — single source of truth for both
  # my.network.ports.<name> (a bare int, consumed everywhere) and the derived
  # read-only my.network.portScope.<name>:
  #   internet  — reachable from the public internet via the Cloudflare tunnel
  #               (ingress allowlist in modules/networking/cloudflared)
  #   lan       — LAN / Tailscale only: a Traefik :443 router with no tunnel
  #               ingress, or a firewall-opened port scraped over the tailnet
  #   localhost — bound to 127.0.0.1, no external reachability
  # Documentation contract — nothing here enforces it; actual routing lives in
  # modules/networking/{traefik,cloudflared} and per-host firewall rules. Keep
  # in sync when adding a service or giving one a public route.
  portDefs = {
    jellyfin = {
      port = 8096;
      scope = "lan";
      desc = "Jellyfin media server";
    };
    transmission = {
      port = 9091;
      scope = "lan";
      desc = "Transmission BitTorrent client web UI";
    };
    audiobookshelf = {
      port = 9292;
      scope = "lan";
      desc = "Audiobookshelf audiobook server";
    };
    tdarr = {
      port = 8265;
      scope = "lan";
      desc = "Tdarr media transcoding web UI";
    };

    sonarr = {
      port = 8990;
      scope = "lan";
      desc = "Sonarr TV shows automation";
    };
    radarr = {
      port = 7878;
      scope = "lan";
      desc = "Radarr movies automation";
    };
    lidarr = {
      port = 8686;
      scope = "lan";
      desc = "Lidarr music automation";
    };
    lazylibrarian = {
      port = 5299;
      scope = "lan";
      desc = "LazyLibrarian ebooks/audiobooks automation";
    };
    bazarr = {
      port = 6767;
      scope = "lan";
      desc = "Bazarr subtitles automation";
    };
    prowlarr = {
      port = 9696;
      scope = "lan";
      desc = "Prowlarr indexer manager";
    };

    prometheus = {
      port = 9090;
      scope = "lan";
      desc = "Prometheus time-series database";
    };
    grafana = {
      port = 3003;
      scope = "lan";
      desc = "Grafana metrics visualization";
    };
    loki = {
      port = 3100;
      scope = "lan";
      desc = "Loki log aggregation server";
    };
    node-exporter = {
      port = 9100;
      scope = "lan";
      desc = "Prometheus node exporter";
    };
    traefik-metrics = {
      port = 8080;
      scope = "localhost";
      desc = "Traefik Prometheus metrics entrypoint (localhost only)";
    };

    miniflux = {
      port = 8086;
      scope = "lan";
      desc = "Miniflux RSS feed reader";
    };
    radicale = {
      port = 5232;
      scope = "internet";
      desc = "Radicale CalDAV/CardDAV server";
    };
    homepage = {
      port = 8082;
      scope = "lan";
      desc = "Homepage application dashboard";
    };

    home-assistant = {
      port = 8123;
      scope = "internet";
      desc = "Home Assistant smart home platform";
    };
    mosquitto = {
      port = 1883;
      scope = "lan";
      desc = "Mosquitto MQTT broker";
    };

    alertmanager = {
      port = 9093;
      scope = "localhost";
      desc = "Prometheus Alertmanager";
    };
    alertmanager-ntfy = {
      port = 9094;
      scope = "localhost";
      desc = "alertmanager-ntfy bridge";
    };

    kapowarr = {
      port = 5656;
      scope = "lan";
      desc = "Kapowarr comics automation web UI";
    };
    seerr = {
      port = 5055;
      scope = "lan";
      desc = "Jellyseerr request management web UI";
    };
    qb = {
      port = 8081;
      scope = "lan";
      desc = "qBittorrent WebUI proxy (host side, forwards into the VPN netns)";
    };

    komf = {
      port = 8085;
      scope = "lan";
      desc = "Komf metadata fetcher web UI";
    };
    komga = {
      port = 8087;
      scope = "lan";
      desc = "Komga comics/manga server";
    };

    microbin = {
      port = 8069;
      scope = "lan";
      desc = "Microbin pastebin/file-sharing service";
    };
    dispatcharr = {
      port = 9191;
      scope = "lan";
      desc = "Dispatcharr IPTV/EPG manager";
    };
    ntfy = {
      port = 9991;
      scope = "internet";
      desc = "ntfy push notification server";
    };

    crowdsec-lapi = {
      port = 8088;
      scope = "lan";
      desc = "CrowdSec local API (LAPI) — local bouncers plus the gcp-relay remote bouncer over Tailscale";
    };
    traefik-api = {
      port = 8083;
      scope = "localhost";
      desc = "Traefik API entrypoint (localhost only, used by the homepage widget)";
    };

    atuin = {
      port = 8881;
      scope = "lan";
      desc = "Atuin shell history sync server";
    };
    nut = {
      port = 3493;
      scope = "lan";
      desc = "Network UPS Tools (NUT) upsd server";
    };
  };

  mkPort = d:
    lib.mkOption {
      type = lib.types.port;
      default = d.port;
      description = d.desc;
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

    # Bare int per service — generated from portDefs above. Unchanged shape
    # for all consumers (config.my.network.ports.<name> is an int).
    ports = lib.mapAttrs (_: mkPort) portDefs;

    # Derived exposure class per service port — see portDefs above.
    portScope = lib.mkOption {
      type = lib.types.attrsOf (lib.types.enum [
        "internet"
        "lan"
        "localhost"
      ]);
      default = lib.mapAttrs (_: d: d.scope) portDefs;
      readOnly = true;
      description = ''
        Exposure class per service port: "internet" (public via the Cloudflare
        tunnel), "lan" (LAN/Tailscale only), "localhost" (127.0.0.1 only).
        Documentation contract, not enforced here — see portDefs in
        modules/options/network.nix.
      '';
    };
  };
}
