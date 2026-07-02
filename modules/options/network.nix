{
  lib,
  config,
  ...
}: {
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
        default = "${config.my.defaults.homeserver_lan}";
        description = "IP address of homeserver — trusted VLAN";
      };

      desktop_lan = lib.mkOption {
        type = lib.types.str;
        default = "${config.my.defaults.desktop_lan}";
        description = "IP address of desktop wired — trusted VLAN";
      };

      desktop_wifi = lib.mkOption {
        type = lib.types.str;
        default = "${config.my.defaults.desktop_wifi}";
        description = "IP address of desktop wireless — trusted VLAN";
      };

      matebook_wifi = lib.mkOption {
        type = lib.types.str;
        default = "${config.my.defaults.matebook_wifi}";
        description = "IP address of Matebook wireless — trusted VLAN";
      };

      homeassistant-vm = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.235";
        description = "Home Assistant VM (QEMU on homeserver) — trusted VLAN";
      };
    };

    # MAC addresses — one attrset per device, co-located with IPs for DRY dhcp.nix
    mac = {
      homeserver = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "homeserver NIC";
      };
      desktop-lan = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "desktop wired NIC";
      };
      desktop-wifi = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "desktop wireless NIC";
      };
      matebook = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "Matebook wireless NIC";
      };
      homeassistant-vm = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "Home Assistant VM virtual NIC";
      };
      switch-office = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "TL-SG108E office switch mgmt";
      };
      switch-livingroom = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "TL-SG108E living room switch mgmt";
      };
      alexa = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "Amazon Echo Show";
      };
      plug-entrance = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "HS103 entrance plug";
      };
      plug-salt = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "HS103 salt lamp plug";
      };
      plug-office = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "HS103 office plug";
      };
      plug-table = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "HS103 table plug";
      };
      plug-window = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "HS103 window plug";
      };
      humidifier = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "Smart humidifier";
      };
      sophia-s23 = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "Sophia Samsung S23 Ultra (note: may randomise)";
      };
      volodymyr-s23 = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "Volodymyr Samsung S23 (note: may randomise)";
      };
      ps5 = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "PlayStation 5";
      };
      nintendo-switch = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "Nintendo Switch OLED";
      };
      mi-box-s = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "Xiaomi Mi Box S";
      };
      roku-tv = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:00";
        description = "Roku TV WiFi";
      };
    };

    # Network infrastructure
    infrastructure = {
      router = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.1";
        description = "NixOS router (Sophos SG110/120)";
      };

      isp-router = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.254";
        description = "ISP router (Technicolor NH20T) — WAN uplink";
      };

      switch-office = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.111";
        description = "Office network switch (TL-SG108E)";
      };

      switch-living-room = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.112";
        description = "Living room network switch (TL-SG108E)";
      };
    };

    # Smart home devices (IoT VLAN — 192.168.20.0/24)
    smart-home = {
      plugs = {
        office = lib.mkOption {
          type = lib.types.str;
          default = "192.168.20.14";
          description = "Office HS103 smart plug — IoT VLAN";
        };

        entrance = lib.mkOption {
          type = lib.types.str;
          default = "192.168.20.11";
          description = "Entrance HS103 smart plug — IoT VLAN";
        };

        table = lib.mkOption {
          type = lib.types.str;
          default = "192.168.20.15";
          description = "Table HS103 smart plug — IoT VLAN";
        };

        window = lib.mkOption {
          type = lib.types.str;
          default = "192.168.20.16";
          description = "Window HS103 smart plug — IoT VLAN";
        };

        salt = lib.mkOption {
          type = lib.types.str;
          default = "192.168.20.12";
          description = "Salt HS103 smart plug — IoT VLAN";
        };
      };

      humidifier = lib.mkOption {
        type = lib.types.str;
        default = "192.168.20.13";
        description = "Smart humidifier — IoT VLAN";
      };

      alexa-echo-show = lib.mkOption {
        type = lib.types.str;
        default = "192.168.20.10";
        description = "Amazon Echo Show — IoT VLAN";
      };
    };

    # Entertainment devices (media VLAN — 192.168.30.0/24)
    entertainment = {
      roku-tv = lib.mkOption {
        type = lib.types.str;
        default = "192.168.30.13";
        description = "Roku TV WiFi — media VLAN";
      };

      mi-box-s = lib.mkOption {
        type = lib.types.str;
        default = "192.168.30.12";
        description = "Xiaomi Mi Box S Android TV — media VLAN";
      };

      playstation-5 = lib.mkOption {
        type = lib.types.str;
        default = "192.168.30.10";
        description = "PlayStation 5 — media VLAN";
      };

      nintendo-switch = lib.mkOption {
        type = lib.types.str;
        default = "192.168.30.11";
        description = "Nintendo Switch OLED — media VLAN";
      };
    };

    # Mobile devices (trusted VLAN — 192.168.1.0/24)
    mobile = {
      sophia-s23-ultra = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.141";
        description = "Sophia's Samsung Galaxy S23 Ultra — trusted VLAN";
      };

      volodymyr-s23 = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.140";
        description = "Volodymyr's Samsung Galaxy S23 — trusted VLAN";
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
