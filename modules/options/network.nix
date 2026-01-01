{
  lib,
  config,
  ...
}: {
  options.my.network = {
    # Gateway
    gateway = lib.mkOption {
      type = lib.types.str;
      default = "${config.my.defaults.gateway}";
      description = "Default gateway - Technicolor NH20T router";
    };

    # Primary systems
    hosts = {
      homeserver_lan = lib.mkOption {
        type = lib.types.str;
        default = "${config.my.defaults.homeserver_lan}";
        description = "IP address of homeserver (Serv) - Main server";
      };

      desktop_lan = lib.mkOption {
        type = lib.types.str;
        default = "${config.my.defaults.desktop_lan}";
        description = "IP address of desktop wired connection";
      };

      desktop_wifi = lib.mkOption {
        type = lib.types.str;
        default = "${config.my.defaults.desktop_wifi}";
        description = "IP address of desktop wireless connection";
      };

      matebook_wifi = lib.mkOption {
        type = lib.types.str;
        default = "${config.my.defaults.matebook_wifi}";
        description = "IP address of Matebook wireless connection";
      };
    };

    # Network infrastructure
    infrastructure = {
      router = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.254";
        description = "Technicolor NH20T router";
      };

      switch-office = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.111";
        description = "Office network switch";
      };

      switch-living-room = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.112";
        description = "Living room network switch";
      };
    };

    # Smart home devices
    smart-home = {
      plugs = {
        office = lib.mkOption {
          type = lib.types.str;
          default = "192.168.1.74";
          description = "Office HS103 smart plug";
        };

        entrance = lib.mkOption {
          type = lib.types.str;
          default = "192.168.1.71";
          description = "Entrance HS103 smart plug";
        };

        table = lib.mkOption {
          type = lib.types.str;
          default = "192.168.1.72";
          description = "Table HS103 smart plug";
        };

        window = lib.mkOption {
          type = lib.types.str;
          default = "192.168.1.73";
          description = "Window HS103 smart plug";
        };

        salt = lib.mkOption {
          type = lib.types.str;
          default = "192.168.1.75";
          description = "Salt HS103 smart plug";
        };
      };

      humidifier = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.70";
        description = "Smart humidifier";
      };

      alexa-echo-show = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.159";
        description = "Amazon Echo Show smart display";
      };
    };

    # Entertainment devices
    entertainment = {
      roku-tv = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.153";
        description = "Roku TV WiFi";
      };

      mi-box-s = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.151";
        description = "Xiaomi Mi Box S Android TV";
      };

      playstation-5 = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.150";
        description = "PlayStation 5 gaming console";
      };

      nintendo-switch = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.152";
        description = "Nintendo Switch OLED";
      };
    };

    # Mobile devices
    mobile = {
      sophia-s23-ultra = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.141";
        description = "Sophia's Samsung Galaxy S23 Ultra";
      };

      volodymyr-s23 = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.140";
        description = "Volodymyr's Samsung Galaxy S23";
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

      kavita = lib.mkOption {
        type = lib.types.port;
        default = 5000;
        description = "Kavita reading/manga server";
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

      readarr = lib.mkOption {
        type = lib.types.port;
        default = 8787;
        description = "Readarr books/ebooks automation";
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

      jellyseerr = lib.mkOption {
        type = lib.types.port;
        default = 5055;
        description = "Jellyseerr media requests";
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

      uptime-kuma = lib.mkOption {
        type = lib.types.port;
        default = 3001;
        description = "Uptime Kuma uptime monitoring";
      };

      # Productivity & Document Management
      paperless = lib.mkOption {
        type = lib.types.port;
        default = 8888;
        description = "Paperless-ngx document management";
      };

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

      flare = lib.mkOption {
        type = lib.types.port;
        default = 3033;
        description = "Flare bookmarks manager";
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
      vaultwarden = lib.mkOption {
        type = lib.types.port;
        default = 8222;
        description = "Vaultwarden password manager";
      };

      authelia = lib.mkOption {
        type = lib.types.port;
        default = 9000;
        description = "Authelia SSO/identity provider";
      };

      # AI & Development
      ollama = lib.mkOption {
        type = lib.types.port;
        default = 11434;
        description = "Ollama AI/LLM model server";
      };
    };
  };
}
