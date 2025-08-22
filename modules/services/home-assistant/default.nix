{
  config,
  pkgs,
  ...
}:
{
  sops.secrets = {
    # --- Home Assistant Secrets ---
    home_assistant_db_password = {
      sopsFile = ../../../secrets/postgresql.yaml;
      key = "hass_db_password";
      owner = config.users.users.postgresql.name;
      group = config.users.groups.postgresql.name;
      mode = "0400";
    };
  };

  users = {
    users = {
      hass = {
        isSystemUser = true;
        group = "hass";
      };
      mosquitto = {
        isSystemUser = true;
        group = "mosquitto";
      };
    };
    groups = {
      mosquitto = { };
      hass = { };
    };
  };

  networking.firewall.allowedTCPPorts = [
    8123 # Home Assistant
    1883 # MQTT
  ];
  networking.firewall.allowedUDPPorts = [
    1883 # MQTT
  ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."hass.example.com" = {
      forceSSL = true;
      sslCertificate = "/var/lib/acme/example.com/fullchain.pem";
      sslCertificateKey = "/var/lib/acme/example.com/key.pem";
      locations."/" = {
        proxyPass = "http://localhost:8123";
        proxyWebsockets = true;
      };
    };
  };

  services.home-assistant = {
    # name = "Home";
    # latitude = "!secret latitude";  # Use secrets
    # longitude = "!secret longitude";
    # Use secrets
    # elevation = "!secret elevation";
    # Use secrets
    # auth_mfa_modules = [ "totp" ];
    # internal_url = "http://localhost:8123";
    # external_url = "https://ha.yourdomain.com";
    enable = true;
    configDir = "/var/lib/home-assistant";
    configWritable = true;
    extraPackages = ps: [
      ps.psycopg2
      ps.pyatv
    ];
    extraComponents = [
      "mqtt"
      "http"
      "roku"
      "alexa_devices"
      "upnp"
      "radio_browser"
      "met"
      "paperless_ngx"
      "playstation_network"
      "jellyfin"
    ];
    config = {
      homeassistant = {
        name = "Lab Home";
        unit_system = "metric";
        time_zone = "America/Edmonton";
        country = "CA";
        currency = "CAD";
        external_url = "https://hass.example.com";
        internal_url = "http://192.168.1.165:8123";
      };
      recorder.db_url = "postgresql://@/hass";

      http = {
        server_host = "0.0.0.0";
        server_port = 8123;
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "192.168.1.165"
        ];
        ip_ban_enabled = true;
        login_attempts_threshold = 5;
      };

      tts = [
        {
          platform = "google_translate";
          language = "en";
        }
      ];

      mqtt = { };

      default_config = { };
      frontend = {
        themes = "!include_dir_merge_named themes";
      };
      shopping_list = { };
      map = { };
      system_health = { };
      logger = {
        default = "info";
        logs = {
          "homeassistant.core" = "debug";
        };
      };
    };
  };

  services.mosquitto = {
    enable = true;
    listeners = [
      {
        acl = [ "pattern readwrite #" ];
        omitPasswordAuth = true;
        settings.allow_anonymous = true;
      }
    ];
  };
}
