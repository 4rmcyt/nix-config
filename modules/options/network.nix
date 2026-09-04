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
    };

    # MAC addresses — one attrset per device, co-located with IPs for DRY dhcp.nix.
    # Values come from the private flake input (net.mac.*).
    mac = let
      macOpt = key: desc:
        lib.mkOption {
          type = lib.types.str;
          default = net.mac.${key};
          description = desc;
        };
    in {
      homeserver = macOpt "homeserver" "homeserver NIC";
      desktop-lan = macOpt "desktop-lan" "desktop wired NIC";
      desktop-wifi = macOpt "desktop-wifi" "desktop wireless NIC";
      matebook = macOpt "matebook" "Matebook wireless NIC";
      homeassistant-vm = macOpt "homeassistant-vm" "Home Assistant VM virtual NIC";
      switch-office = macOpt "switch-office" "TL-SG108E office switch mgmt";
      switch-livingroom = macOpt "switch-livingroom" "TL-SG108E living room switch mgmt";
      alexa = macOpt "alexa" "Amazon Echo Show";
      plug-entrance = macOpt "plug-entrance" "HS103 entrance plug";
      plug-salt = macOpt "plug-salt" "HS103 salt lamp plug";
      plug-office = macOpt "plug-office" "HS103 office plug";
      plug-table = macOpt "plug-table" "HS103 table plug";
      plug-window = macOpt "plug-window" "HS103 window plug";
      humidifier = macOpt "humidifier" "Smart humidifier";
      sophia-s23 = macOpt "sophia-s23" "phone A (note: may randomise)";
      volodymyr-s23 = macOpt "volodymyr-s23" "phone B (note: may randomise)";
      ps5 = macOpt "ps5" "PlayStation 5";
      nintendo-switch = macOpt "nintendo-switch" "Nintendo Switch OLED";
      mi-box-s = macOpt "mi-box-s" "Xiaomi Mi Box S";
      roku-tv = macOpt "roku-tv" "Roku TV WiFi";
    };

    # Network infrastructure — values from the private flake input.
    infrastructure = {
      router = lib.mkOption {
        type = lib.types.str;
        default = net.infrastructure.router;
        description = "NixOS router (Sophos SG110/120)";
      };

      isp-router = lib.mkOption {
        type = lib.types.str;
        default = net.infrastructure."isp-router";
        description = "ISP router (Technicolor NH20T) — WAN uplink";
      };

      switch-office = lib.mkOption {
        type = lib.types.str;
        default = net.infrastructure."switch-office";
        description = "Office network switch (TL-SG108E)";
      };

      switch-living-room = lib.mkOption {
        type = lib.types.str;
        default = net.infrastructure."switch-living-room";
        description = "Living room network switch (TL-SG108E)";
      };
    };

    # Smart home devices (IoT VLAN — 192.168.20.0/24) — values from private input.
    smart-home = {
      plugs = {
        office = lib.mkOption {
          type = lib.types.str;
          default = net."smart-home".plugs.office;
          description = "Office HS103 smart plug — IoT VLAN";
        };

        entrance = lib.mkOption {
          type = lib.types.str;
          default = net."smart-home".plugs.entrance;
          description = "Entrance HS103 smart plug — IoT VLAN";
        };

        table = lib.mkOption {
          type = lib.types.str;
          default = net."smart-home".plugs.table;
          description = "Table HS103 smart plug — IoT VLAN";
        };

        window = lib.mkOption {
          type = lib.types.str;
          default = net."smart-home".plugs.window;
          description = "Window HS103 smart plug — IoT VLAN";
        };

        salt = lib.mkOption {
          type = lib.types.str;
          default = net."smart-home".plugs.salt;
          description = "Salt HS103 smart plug — IoT VLAN";
        };
      };

      humidifier = lib.mkOption {
        type = lib.types.str;
        default = net."smart-home".humidifier;
        description = "Smart humidifier — IoT VLAN";
      };

      alexa-echo-show = lib.mkOption {
        type = lib.types.str;
        default = net."smart-home"."alexa-echo-show";
        description = "Amazon Echo Show — IoT VLAN";
      };
    };

    # Entertainment devices (media VLAN — 192.168.30.0/24) — values from private input.
    entertainment = {
      roku-tv = lib.mkOption {
        type = lib.types.str;
        default = net.entertainment."roku-tv";
        description = "Roku TV WiFi — media VLAN";
      };

      mi-box-s = lib.mkOption {
        type = lib.types.str;
        default = net.entertainment."mi-box-s";
        description = "Xiaomi Mi Box S Android TV — media VLAN";
      };

      playstation-5 = lib.mkOption {
        type = lib.types.str;
        default = net.entertainment."playstation-5";
        description = "PlayStation 5 — media VLAN";
      };

      nintendo-switch = lib.mkOption {
        type = lib.types.str;
        default = net.entertainment."nintendo-switch";
        description = "Nintendo Switch OLED — media VLAN";
      };
    };

    # Mobile devices (trusted VLAN — 192.168.1.0/24) — values from private input.
    mobile = {
      sophia-s23-ultra = lib.mkOption {
        type = lib.types.str;
        default = net.mobile."sophia-s23-ultra";
        description = "phone A — trusted VLAN";
      };

      volodymyr-s23 = lib.mkOption {
        type = lib.types.str;
        default = net.mobile."volodymyr-s23";
        description = "phone B — trusted VLAN";
      };
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
        default = 8089;
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

      # Security & Authentication

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
    };
  };
}
